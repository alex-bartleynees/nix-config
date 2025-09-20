use anyhow::{Context, Result};
use log::{debug, warn};
use rayon::prelude::*;
use std::collections::HashSet;
use std::fs::{self, Metadata};
use std::os::unix::fs::{MetadataExt, PermissionsExt};
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};
use std::sync::atomic::{AtomicUsize, Ordering};
use walkdir::WalkDir;

#[derive(Debug, Clone)]
pub struct FileInfo {
    pub path: PathBuf,
    pub is_dir: bool,
    pub metadata: Option<FileMetadata>,
}

#[derive(Debug, Clone)]
pub struct FileMetadata {
    pub mode: u32,
    pub uid: u32,
    pub gid: u32,
    pub size: u64,
}

impl From<&Metadata> for FileMetadata {
    fn from(metadata: &Metadata) -> Self {
        Self {
            mode: metadata.permissions().mode(),
            uid: metadata.uid(),
            gid: metadata.gid(),
            size: metadata.len(),
        }
    }
}

pub struct FileOperations {
    pub copied_files: AtomicUsize,
    pub copied_dirs: AtomicUsize,
    pub total_bytes: AtomicUsize,
}

impl FileOperations {
    pub fn new() -> Self {
        Self {
            copied_files: AtomicUsize::new(0),
            copied_dirs: AtomicUsize::new(0),
            total_bytes: AtomicUsize::new(0),
        }
    }

    pub fn count_files<P: AsRef<Path>>(&self, path: P) -> Result<usize> {
        let path = path.as_ref();
        debug!("Counting files in {:?}", path);

        let count = WalkDir::new(path)
            .into_iter()
            .filter_map(|e| e.ok())
            .filter(|e| e.file_type().is_file())
            .count();

        debug!("Found {} files in {:?}", count, path);
        Ok(count)
    }

    pub fn extract_persistent_files(
        &self,
        subvolume_mount_point: &Path,
        paths_to_keep: &[String],
        source_subvolume: &Path,
        fresh_snapshot: &Path,
    ) -> Result<()> {
        debug!("Extracting persistent files");
        debug!("Subvolume mount point: {:?}", subvolume_mount_point);
        debug!("Source subvolume: {:?}", source_subvolume);
        debug!("Fresh snapshot: {:?}", fresh_snapshot);

        // Filter paths that belong to this subvolume
        let relevant_paths: Vec<_> = paths_to_keep
            .iter()
            .filter(|path| self.path_belongs_to_subvolume(path, subvolume_mount_point))
            .collect();

        debug!("Processing {} relevant paths for this subvolume", relevant_paths.len());

        // Process paths in parallel
        relevant_paths
            .par_iter()
            .try_for_each(|path_to_keep| -> Result<()> {
                self.copy_persistent_path(
                    path_to_keep,
                    subvolume_mount_point,
                    source_subvolume,
                    fresh_snapshot,
                )
            })?;

        debug!("Persistent file extraction completed");
        Ok(())
    }

    fn path_belongs_to_subvolume(&self, path: &str, subvolume_mount_point: &Path) -> bool {
        if subvolume_mount_point == Path::new("/") {
            // For root subvolume, exclude /home paths which belong to @home subvolume
            !path.starts_with("/home/")
        } else {
            // For non-root subvolumes, handle paths that start with the mount point
            path.starts_with(&format!("{}/", subvolume_mount_point.display()))
                || path == subvolume_mount_point.to_string_lossy()
        }
    }

    fn copy_persistent_path(
        &self,
        path_to_keep: &str,
        subvolume_mount_point: &Path,
        source_subvolume: &Path,
        fresh_snapshot: &Path,
    ) -> Result<()> {
        // Calculate relative path
        let rel_path = if subvolume_mount_point == Path::new("/") {
            path_to_keep.strip_prefix('/').unwrap_or(path_to_keep)
        } else {
            let mount_str = subvolume_mount_point.to_string_lossy();
            path_to_keep
                .strip_prefix(&format!("{}/", mount_str))
                .or_else(|| path_to_keep.strip_prefix(&*mount_str))
                .unwrap_or(path_to_keep)
        };

        let source_path = source_subvolume.join(rel_path);
        let target_path = fresh_snapshot.join(rel_path);

        if !source_path.exists() {
            warn!("Persistent path not found: {:?}", source_path);
            return Ok(());
        }

        // Create parent directories
        if let Some(parent) = target_path.parent() {
            self.create_path_with_ownership(&source_path, parent, fresh_snapshot, source_subvolume)?;
        }

        // Copy the actual file or directory
        if source_path.is_dir() {
            self.copy_directory_contents(&source_path, &target_path)?;
            debug!("Copied directory: {:?} -> {:?}", source_path, target_path);
        } else {
            self.copy_file_with_reflink(&source_path, &target_path)?;
            debug!("Copied file: {:?} -> {:?}", source_path, target_path);
        }

        Ok(())
    }

    fn create_path_with_ownership(
        &self,
        source_path: &Path,
        target_parent: &Path,
        fresh_snapshot: &Path,
        source_subvolume: &Path,
    ) -> Result<()> {
        if target_parent.exists() {
            return Ok(());
        }

        // Recursively create parent directories
        if let Some(grandparent) = target_parent.parent() {
            if grandparent != fresh_snapshot {
                self.create_path_with_ownership(source_path, grandparent, fresh_snapshot, source_subvolume)?;
            }
        }

        // Create the directory
        fs::create_dir_all(target_parent)
            .with_context(|| format!("Failed to create directory {:?}", target_parent))?;

        // Set ownership to match source
        let relative_target = target_parent.strip_prefix(fresh_snapshot)
            .with_context(|| format!("Failed to strip prefix from {:?}", target_parent))?;
        let corresponding_source = source_subvolume.join(relative_target);

        if corresponding_source.exists() {
            if let Ok(metadata) = corresponding_source.metadata() {
                self.set_ownership(target_parent, metadata.uid(), metadata.gid())?;
            }
        }

        Ok(())
    }

    fn copy_directory_contents(&self, source: &Path, target: &Path) -> Result<()> {
        if !target.exists() {
            fs::create_dir_all(target)
                .with_context(|| format!("Failed to create target directory {:?}", target))?;

            // Copy metadata
            if let Ok(metadata) = source.metadata() {
                self.set_ownership(target, metadata.uid(), metadata.gid())?;
                self.set_permissions(target, metadata.permissions().mode())?;
            }
        }

        // Use cp command for efficient copying with reflinks
        let output = Command::new("cp")
            .args([
                "-a",
                "--preserve=all",
                "--reflink=auto",
                &format!("{}/.", source.display()),
                &format!("{}/", target.display()),
            ])
            .stdout(Stdio::null())
            .stderr(Stdio::piped())
            .output()
            .context("Failed to execute cp command")?;

        if !output.status.success() {
            let stderr = String::from_utf8_lossy(&output.stderr);
            anyhow::bail!("Failed to copy directory contents from {:?} to {:?}: {}", source, target, stderr);
        }

        self.copied_dirs.fetch_add(1, Ordering::Relaxed);
        Ok(())
    }

    fn copy_file_with_reflink(&self, source: &Path, target: &Path) -> Result<()> {
        // Use cp command for efficient copying with reflinks
        let output = Command::new("cp")
            .args([
                "-a",
                "--preserve=all",
                "--reflink=auto",
                source.to_str().unwrap(),
                target.to_str().unwrap(),
            ])
            .stdout(Stdio::null())
            .stderr(Stdio::piped())
            .output()
            .context("Failed to execute cp command")?;

        if !output.status.success() {
            let stderr = String::from_utf8_lossy(&output.stderr);
            anyhow::bail!("Failed to copy file from {:?} to {:?}: {}", source, target, stderr);
        }

        if let Ok(metadata) = source.metadata() {
            self.total_bytes.fetch_add(metadata.len() as usize, Ordering::Relaxed);
        }
        self.copied_files.fetch_add(1, Ordering::Relaxed);
        Ok(())
    }

    fn set_ownership(&self, path: &Path, uid: u32, gid: u32) -> Result<()> {
        let output = Command::new("chown")
            .args([&format!("{}:{}", uid, gid), path.to_str().unwrap()])
            .stdout(Stdio::null())
            .stderr(Stdio::piped())
            .output()
            .context("Failed to execute chown command")?;

        if !output.status.success() {
            let stderr = String::from_utf8_lossy(&output.stderr);
            warn!("Failed to set ownership for {:?}: {}", path, stderr);
        }

        Ok(())
    }

    fn set_permissions(&self, path: &Path, mode: u32) -> Result<()> {
        let permissions = fs::Permissions::from_mode(mode);
        fs::set_permissions(path, permissions)
            .with_context(|| format!("Failed to set permissions for {:?}", path))?;
        Ok(())
    }

    pub fn clear_subvolume_contents(
        &self,
        subvolume: &Path,
        paths_to_keep: &[String],
        btrfs_manager: &crate::btrfs::BtrfsManager,
    ) -> Result<()> {
        debug!("Clearing contents of subvolume: {:?}", subvolume);
        debug!("Paths to preserve: {:?}", paths_to_keep);

        if !subvolume.is_dir() {
            warn!("Subvolume directory does not exist: {:?}", subvolume);
            return Ok(());
        }

        // Critical directories/files to always preserve
        let critical_paths: HashSet<&str> = ["nix", ".snapshots", "@snapshots", "boot"]
            .iter()
            .cloned()
            .collect();

        debug!("Critical paths to preserve: {:?}", critical_paths);

        // Handle systemd-created subvolumes in /var specifically
        self.handle_systemd_subvolumes(subvolume, btrfs_manager)?;

        // Collect entries to process
        let entries: Vec<_> = fs::read_dir(subvolume)
            .with_context(|| format!("Failed to read directory {:?}", subvolume))?
            .filter_map(|e| e.ok())
            .collect();

        // Process entries in parallel where safe
        let (subvolume_entries, regular_entries): (Vec<_>, Vec<_>) = entries
            .into_iter()
            .partition(|entry| {
                entry.path().is_dir()
                    && btrfs_manager.is_subvolume(&entry.path()).unwrap_or(false)
            });

        // Handle subvolumes sequentially (not thread-safe)
        for entry in subvolume_entries {
            let path = entry.path();
            let basename = path.file_name()
                .and_then(|n| n.to_str())
                .unwrap_or("");

            if critical_paths.contains(basename) {
                debug!("Preserving critical subvolume: {:?}", path);
            } else {
                debug!("Deleting non-critical subvolume: {:?}", path);
                if let Err(e) = btrfs_manager.delete_subvolume(&path) {
                    warn!("Failed to delete subvolume {:?}: {}", path, e);
                    btrfs_manager.delete_subvolume_recursively(&path)?;
                }
            }
        }

        // Handle regular files/directories in parallel
        regular_entries
            .par_iter()
            .try_for_each(|entry| -> Result<()> {
                let path = entry.path();
                let basename = path.file_name()
                    .and_then(|n| n.to_str())
                    .unwrap_or("");

                if critical_paths.contains(basename) {
                    debug!("Preserving critical path: {:?}", path);
                } else {
                    debug!("Removing non-critical item: {:?}", path);
                    if path.is_dir() {
                        fs::remove_dir_all(&path)
                            .unwrap_or_else(|e| warn!("Failed to remove directory {:?}: {}", path, e));
                    } else {
                        fs::remove_file(&path)
                            .unwrap_or_else(|e| warn!("Failed to remove file {:?}: {}", path, e));
                    }
                }
                Ok(())
            })?;

        debug!("Subvolume contents cleared successfully");
        Ok(())
    }

    fn handle_systemd_subvolumes(
        &self,
        subvolume: &Path,
        btrfs_manager: &crate::btrfs::BtrfsManager,
    ) -> Result<()> {
        // Check if this is a subvolume that might contain systemd subvolumes
        let subvolume_str = subvolume.to_string_lossy();
        if !subvolume_str.contains("@var") && !subvolume_str.ends_with("/var") && !subvolume.join("var").exists() {
            return Ok(());
        }

        debug!("Handling systemd subvolumes in var directory");

        let systemd_subvols = [
            subvolume.join("var/lib/portables"),
            subvolume.join("var/lib/machines"),
        ];

        for systemd_subvol in &systemd_subvols {
            if systemd_subvol.exists() && btrfs_manager.is_subvolume(systemd_subvol)? {
                debug!("Found systemd subvolume, deleting: {:?}", systemd_subvol);
                if let Err(e) = btrfs_manager.delete_subvolume(systemd_subvol) {
                    warn!("Failed to delete systemd subvolume {:?}: {}", systemd_subvol, e);
                }
            }
        }

        Ok(())
    }

    pub fn copy_persistent_files_fast(
        &self,
        persistent_subvol: &Path,
        target_subvolume: &Path,
    ) -> Result<()> {
        debug!("Copying persistent files from {:?} to {:?}", persistent_subvol, target_subvolume);

        // Check if persistent subvolume has any content
        let file_count = self.count_files(persistent_subvol)?;
        debug!("Found {} files in persistent subvolume", file_count);

        if file_count == 0 {
            debug!("No persistent files to transfer, skipping");
            return Ok(());
        }

        debug!("Using optimized file copy to transfer persistent files");

        if !persistent_subvol.is_dir() || !target_subvolume.is_dir() {
            anyhow::bail!(
                "Source or target directory does not exist. Source: {}, Target: {}",
                persistent_subvol.exists(),
                target_subvolume.exists()
            );
        }

        // Use cp command for maximum efficiency with reflinks
        let output = Command::new("cp")
            .args([
                "-a",
                "--preserve=all",
                "--reflink=auto",
                &format!("{}/.", persistent_subvol.display()),
                &format!("{}/", target_subvolume.display()),
            ])
            .stdout(Stdio::piped())
            .stderr(Stdio::piped())
            .output()
            .context("Failed to execute cp command")?;

        if !output.status.success() {
            let stderr = String::from_utf8_lossy(&output.stderr);
            anyhow::bail!("Failed to copy persistent files: {}", stderr);
        }

        debug!("Successfully copied persistent files");
        Ok(())
    }

    pub fn get_stats(&self) -> (usize, usize, usize) {
        (
            self.copied_files.load(Ordering::Relaxed),
            self.copied_dirs.load(Ordering::Relaxed),
            self.total_bytes.load(Ordering::Relaxed),
        )
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::fs::{create_dir_all, File};
    use std::io::Write;
    use tempfile::TempDir;

    fn create_test_file_ops() -> FileOperations {
        FileOperations::new()
    }

    fn create_test_file_structure(base_dir: &Path) -> Result<()> {
        // Create test directories
        create_dir_all(base_dir.join("dir1"))?;
        create_dir_all(base_dir.join("dir1/subdir"))?;
        create_dir_all(base_dir.join("dir2"))?;

        // Create test files
        let mut file1 = File::create(base_dir.join("file1.txt"))?;
        writeln!(file1, "test content 1")?;

        let mut file2 = File::create(base_dir.join("dir1/file2.txt"))?;
        writeln!(file2, "test content 2")?;

        let mut file3 = File::create(base_dir.join("dir1/subdir/file3.txt"))?;
        writeln!(file3, "test content 3")?;

        Ok(())
    }

    #[test]
    fn test_new_file_operations() {
        let ops = create_test_file_ops();
        let (files, dirs, bytes) = ops.get_stats();
        assert_eq!(files, 0);
        assert_eq!(dirs, 0);
        assert_eq!(bytes, 0);
    }

    #[test]
    fn test_count_files() -> Result<()> {
        let temp_dir = TempDir::new()?;
        let base_path = temp_dir.path();

        create_test_file_structure(base_path)?;

        let ops = create_test_file_ops();
        let count = ops.count_files(base_path)?;

        assert_eq!(count, 3); // Should find 3 files
        Ok(())
    }

    #[test]
    fn test_count_files_empty_directory() -> Result<()> {
        let temp_dir = TempDir::new()?;
        let base_path = temp_dir.path();

        let ops = create_test_file_ops();
        let count = ops.count_files(base_path)?;

        assert_eq!(count, 0);
        Ok(())
    }

    #[test]
    fn test_path_belongs_to_subvolume_root() {
        let ops = create_test_file_ops();
        let root_mount = Path::new("/");

        // Root subvolume should handle non-home paths
        assert!(ops.path_belongs_to_subvolume("/etc/ssh", root_mount));
        assert!(ops.path_belongs_to_subvolume("/var/log", root_mount));

        // Root subvolume should NOT handle home paths
        assert!(!ops.path_belongs_to_subvolume("/home/user", root_mount));
        assert!(!ops.path_belongs_to_subvolume("/home/user/file.txt", root_mount));
    }

    #[test]
    fn test_path_belongs_to_subvolume_home() {
        let ops = create_test_file_ops();
        let home_mount = Path::new("/home");

        // Home subvolume should handle home paths
        assert!(ops.path_belongs_to_subvolume("/home/user", home_mount));
        assert!(ops.path_belongs_to_subvolume("/home/user/.config", home_mount));

        // Home subvolume should NOT handle non-home paths
        assert!(!ops.path_belongs_to_subvolume("/etc/ssh", home_mount));
        assert!(!ops.path_belongs_to_subvolume("/var/log", home_mount));
    }

    #[test]
    fn test_path_belongs_to_subvolume_exact_match() {
        let ops = create_test_file_ops();
        let mount = Path::new("/var");

        // Should match exact path
        assert!(ops.path_belongs_to_subvolume("/var", mount));
        assert!(ops.path_belongs_to_subvolume("/var/", mount));
        assert!(ops.path_belongs_to_subvolume("/var/log", mount));

        // Should not match different paths
        assert!(!ops.path_belongs_to_subvolume("/home", mount));
        assert!(!ops.path_belongs_to_subvolume("/etc", mount));
    }

    #[test]
    fn test_get_stats_initial() {
        let ops = create_test_file_ops();
        let (files, dirs, bytes) = ops.get_stats();

        assert_eq!(files, 0);
        assert_eq!(dirs, 0);
        assert_eq!(bytes, 0);
    }

    #[test]
    fn test_atomic_counters() {
        let ops = create_test_file_ops();

        // Test atomic increments
        ops.copied_files.fetch_add(5, Ordering::Relaxed);
        ops.copied_dirs.fetch_add(3, Ordering::Relaxed);
        ops.total_bytes.fetch_add(1024, Ordering::Relaxed);

        let (files, dirs, bytes) = ops.get_stats();
        assert_eq!(files, 5);
        assert_eq!(dirs, 3);
        assert_eq!(bytes, 1024);
    }

    #[test]
    fn test_file_metadata_from_metadata() {
        // This test requires creating actual files to get real metadata
        let temp_dir = TempDir::new().unwrap();
        let file_path = temp_dir.path().join("test_file.txt");

        let mut file = File::create(&file_path).unwrap();
        writeln!(file, "test content").unwrap();
        drop(file);

        let metadata = std::fs::metadata(&file_path).unwrap();
        let file_metadata = FileMetadata::from(&metadata);

        assert_eq!(file_metadata.size, metadata.len());
        assert_eq!(file_metadata.uid, metadata.uid());
        assert_eq!(file_metadata.gid, metadata.gid());
        assert_eq!(file_metadata.mode, metadata.permissions().mode());
    }

    #[test]
    fn test_file_info_debug() {
        let temp_dir = TempDir::new().unwrap();
        let file_path = temp_dir.path().join("test.txt");

        let info = FileInfo {
            path: file_path.clone(),
            is_dir: false,
            metadata: Some(FileMetadata {
                mode: 0o644,
                uid: 1000,
                gid: 1000,
                size: 42,
            }),
        };

        let debug_str = format!("{:?}", info);
        assert!(debug_str.contains("test.txt"));
        assert!(debug_str.contains("is_dir: false"));
    }

    #[test]
    fn test_file_metadata_debug() {
        let metadata = FileMetadata {
            mode: 0o755,
            uid: 1000,
            gid: 1000,
            size: 1024,
        };

        let debug_str = format!("{:?}", metadata);
        assert!(debug_str.contains("mode: 493")); // 0o755 in decimal
        assert!(debug_str.contains("uid: 1000"));
        assert!(debug_str.contains("size: 1024"));
    }

    #[test]
    fn test_clone_file_info() {
        let file_info = FileInfo {
            path: PathBuf::from("/test/path"),
            is_dir: true,
            metadata: None,
        };

        let cloned = file_info.clone();
        assert_eq!(cloned.path, file_info.path);
        assert_eq!(cloned.is_dir, file_info.is_dir);
        assert!(cloned.metadata.is_none());
    }

    #[test]
    fn test_clone_file_metadata() {
        let metadata = FileMetadata {
            mode: 0o644,
            uid: 1000,
            gid: 1000,
            size: 512,
        };

        let cloned = metadata.clone();
        assert_eq!(cloned.mode, metadata.mode);
        assert_eq!(cloned.uid, metadata.uid);
        assert_eq!(cloned.gid, metadata.gid);
        assert_eq!(cloned.size, metadata.size);
    }

    // Integration tests with actual file operations
    mod integration_tests {
        use super::*;

        #[test]
        fn test_extract_persistent_files_empty_paths() -> Result<()> {
            let temp_dir = TempDir::new()?;
            let source_dir = temp_dir.path().join("source");
            let target_dir = temp_dir.path().join("target");

            create_dir_all(&source_dir)?;
            create_dir_all(&target_dir)?;

            let ops = create_test_file_ops();
            let empty_paths: Vec<String> = vec![];

            // Should not fail with empty paths
            ops.extract_persistent_files(
                Path::new("/"),
                &empty_paths,
                &source_dir,
                &target_dir,
            )?;

            Ok(())
        }

        #[test]
        fn test_copy_persistent_files_fast_empty_source() -> Result<()> {
            let temp_dir = TempDir::new()?;
            let source_dir = temp_dir.path().join("source");
            let target_dir = temp_dir.path().join("target");

            create_dir_all(&source_dir)?;
            create_dir_all(&target_dir)?;

            let ops = create_test_file_ops();

            // Should handle empty source directory gracefully
            ops.copy_persistent_files_fast(&source_dir, &target_dir)?;

            Ok(())
        }

        #[test]
        fn test_copy_persistent_files_fast_with_content() -> Result<()> {
            let temp_dir = TempDir::new()?;
            let source_dir = temp_dir.path().join("source");
            let target_dir = temp_dir.path().join("target");

            create_dir_all(&source_dir)?;
            create_dir_all(&target_dir)?;
            create_test_file_structure(&source_dir)?;

            let ops = create_test_file_ops();

            // Should copy files successfully
            ops.copy_persistent_files_fast(&source_dir, &target_dir)?;

            // Verify files were copied
            assert!(target_dir.join("file1.txt").exists());
            assert!(target_dir.join("dir1/file2.txt").exists());
            assert!(target_dir.join("dir1/subdir/file3.txt").exists());

            Ok(())
        }

        #[test]
        fn test_count_files_with_nested_structure() -> Result<()> {
            let temp_dir = TempDir::new()?;
            let base_dir = temp_dir.path();

            // Create a more complex structure
            create_dir_all(base_dir.join("level1/level2/level3"))?;

            for i in 1..=5 {
                File::create(base_dir.join(format!("file{}.txt", i)))?;
            }

            for i in 1..=3 {
                File::create(base_dir.join(format!("level1/file{}.txt", i)))?;
            }

            File::create(base_dir.join("level1/level2/deep_file.txt"))?;

            let ops = create_test_file_ops();
            let count = ops.count_files(base_dir)?;

            assert_eq!(count, 9); // 5 + 3 + 1 files
            Ok(())
        }
    }

    // Error handling tests
    mod error_tests {
        use super::*;

        #[test]
        fn test_count_files_nonexistent_directory() {
            let ops = create_test_file_ops();
            let nonexistent = Path::new("/definitely/does/not/exist");

            // Should handle nonexistent directory gracefully
            let result = ops.count_files(nonexistent);
            assert!(result.is_err() || result.unwrap() == 0);
        }

        #[test]
        fn test_copy_persistent_files_fast_nonexistent_source() {
            let temp_dir = TempDir::new().unwrap();
            let nonexistent_source = temp_dir.path().join("nonexistent");
            let target_dir = temp_dir.path().join("target");

            create_dir_all(&target_dir).unwrap();

            let ops = create_test_file_ops();

            // First test that count_files fails on nonexistent directory
            let count_result = ops.count_files(&nonexistent_source);
            if count_result.is_ok() && count_result.unwrap() == 0 {
                // If count_files returns 0 for nonexistent dirs, then copy should succeed
                let result = ops.copy_persistent_files_fast(&nonexistent_source, &target_dir);
                assert!(result.is_ok());
            } else {
                // If count_files fails, then copy should fail
                let result = ops.copy_persistent_files_fast(&nonexistent_source, &target_dir);
                assert!(result.is_err());
            }
        }

        #[test]
        fn test_copy_persistent_files_fast_nonexistent_target() {
            let temp_dir = TempDir::new().unwrap();
            let source_dir = temp_dir.path().join("source");
            let nonexistent_target = temp_dir.path().join("nonexistent");

            create_dir_all(&source_dir).unwrap();
            create_test_file_structure(&source_dir).unwrap();

            let ops = create_test_file_ops();
            let result = ops.copy_persistent_files_fast(&source_dir, &nonexistent_target);

            // Should fail with nonexistent target
            assert!(result.is_err());
        }
    }
}