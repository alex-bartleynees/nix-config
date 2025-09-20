use anyhow::{Context, Result};
use log::{debug, warn};
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};

#[derive(Debug, Clone)]
pub struct SubvolumeInfo {
    pub id: u64,
    pub path: String,
}

pub struct BtrfsManager {
    device: PathBuf,
    pub mount_point: PathBuf,
}

impl BtrfsManager {
    pub fn new<P1: AsRef<Path>, P2: AsRef<Path>>(device: P1, mount_point: P2) -> Self {
        Self {
            device: device.as_ref().to_path_buf(),
            mount_point: mount_point.as_ref().to_path_buf(),
        }
    }

    pub fn mount_root(&self) -> Result<()> {
        debug!("Mounting root subvolume from {:?} to {:?}", self.device, self.mount_point);

        std::fs::create_dir_all(&self.mount_point)
            .context("Failed to create mount point")?;

        let output = Command::new("mount")
            .args([
                "-t", "btrfs",
                "-o", "subvolid=5,user_subvol_rm_allowed",
                self.device.to_str().unwrap(),
                self.mount_point.to_str().unwrap(),
            ])
            .stdout(Stdio::piped())
            .stderr(Stdio::piped())
            .output()
            .context("Failed to execute mount command")?;

        if !output.status.success() {
            let stderr = String::from_utf8_lossy(&output.stderr);
            anyhow::bail!("Failed to mount root subvolume: {}", stderr);
        }

        debug!("Root subvolume mounted successfully");
        Ok(())
    }

    pub fn unmount(&self) -> Result<()> {
        debug!("Unmounting {:?}", self.mount_point);

        let output = Command::new("umount")
            .args(["-R", self.mount_point.to_str().unwrap()])
            .stdout(Stdio::piped())
            .stderr(Stdio::piped())
            .output()
            .context("Failed to execute umount command")?;

        if !output.status.success() {
            let stderr = String::from_utf8_lossy(&output.stderr);
            warn!("Failed to unmount cleanly: {}", stderr);
        }

        if self.mount_point.exists() {
            std::fs::remove_dir_all(&self.mount_point)
                .context("Failed to remove mount point directory")?;
        }

        Ok(())
    }

    pub fn list_subvolumes(&self) -> Result<Vec<SubvolumeInfo>> {
        debug!("Listing subvolumes in {:?}", self.mount_point);

        let output = Command::new("btrfs")
            .args(["subvolume", "list", self.mount_point.to_str().unwrap()])
            .stdout(Stdio::piped())
            .stderr(Stdio::piped())
            .output()
            .context("Failed to list subvolumes")?;

        if !output.status.success() {
            let stderr = String::from_utf8_lossy(&output.stderr);
            anyhow::bail!("Failed to list subvolumes: {}", stderr);
        }

        let stdout = String::from_utf8_lossy(&output.stdout);
        let mut subvolumes = Vec::new();

        for line in stdout.lines() {
            if let Some(info) = self.parse_subvolume_line(line) {
                subvolumes.push(info);
            }
        }

        Ok(subvolumes)
    }

    pub fn parse_subvolume_line(&self, line: &str) -> Option<SubvolumeInfo> {
        // Parse lines like: "ID 256 gen 85 top level 5 path @"
        let parts: Vec<&str> = line.split_whitespace().collect();
        if parts.len() >= 8 && parts[0] == "ID" {
            // Find the "path" keyword
            if let Some(path_index) = parts.iter().position(|&part| part == "path") {
                if path_index + 1 < parts.len() {
                    if let Ok(id) = parts[1].parse::<u64>() {
                        let path = parts[path_index + 1..].join(" ");
                        return Some(SubvolumeInfo { id, path });
                    }
                }
            }
        }
        None
    }

    pub fn mount_subvolume(&self, subvolume_name: &str) -> Result<PathBuf> {
        let subvol_mount = self.mount_point.join(subvolume_name);
        debug!("Mounting subvolume {} to {:?}", subvolume_name, subvol_mount);

        std::fs::create_dir_all(&subvol_mount)
            .context("Failed to create subvolume mount point")?;

        // Check if subvolume exists
        if !self.subvolume_exists(subvolume_name)? {
            warn!("Subvolume {} does not exist, skipping mount", subvolume_name);
            return Ok(subvol_mount);
        }

        let output = Command::new("mount")
            .args([
                "-t", "btrfs",
                "-o", &format!("subvol={},user_subvol_rm_allowed", subvolume_name),
                self.device.to_str().unwrap(),
                subvol_mount.to_str().unwrap(),
            ])
            .stdout(Stdio::piped())
            .stderr(Stdio::piped())
            .output()
            .context("Failed to execute mount command")?;

        if !output.status.success() {
            let stderr = String::from_utf8_lossy(&output.stderr);
            warn!("Failed to mount subvolume {}: {}", subvolume_name, stderr);
        } else {
            debug!("Successfully mounted {}", subvolume_name);
        }

        Ok(subvol_mount)
    }

    pub fn subvolume_exists(&self, subvolume_name: &str) -> Result<bool> {
        let subvol_path = self.mount_point.join(subvolume_name);

        let output = Command::new("btrfs")
            .args(["subvolume", "show", subvol_path.to_str().unwrap()])
            .stdout(Stdio::null())
            .stderr(Stdio::null())
            .output()
            .context("Failed to check subvolume existence")?;

        Ok(output.status.success())
    }

    pub fn create_subvolume<P: AsRef<Path>>(&self, path: P) -> Result<()> {
        let path = path.as_ref();
        debug!("Creating subvolume at {:?}", path);

        if let Some(parent) = path.parent() {
            std::fs::create_dir_all(parent)
                .context("Failed to create parent directory")?;
        }

        let output = Command::new("btrfs")
            .args(["subvolume", "create", path.to_str().unwrap()])
            .stdout(Stdio::piped())
            .stderr(Stdio::piped())
            .output()
            .context("Failed to create subvolume")?;

        if !output.status.success() {
            let stderr = String::from_utf8_lossy(&output.stderr);
            anyhow::bail!("Failed to create subvolume: {}", stderr);
        }

        debug!("Successfully created subvolume at {:?}", path);
        Ok(())
    }

    pub fn delete_subvolume<P: AsRef<Path>>(&self, path: P) -> Result<()> {
        let path = path.as_ref();

        if !path.exists() {
            debug!("Subvolume {:?} does not exist, skipping deletion", path);
            return Ok(());
        }

        debug!("Deleting subvolume at {:?}", path);

        let output = Command::new("btrfs")
            .args(["subvolume", "delete", "--commit-after", path.to_str().unwrap()])
            .stdout(Stdio::piped())
            .stderr(Stdio::piped())
            .output()
            .context("Failed to delete subvolume")?;

        if !output.status.success() {
            let stderr = String::from_utf8_lossy(&output.stderr);
            warn!("Failed to delete subvolume {:?}: {}", path, stderr);
            self.delete_subvolume_recursively(path)?;
        } else {
            debug!("Successfully deleted subvolume at {:?}", path);
        }

        Ok(())
    }

    pub fn delete_subvolume_recursively<P: AsRef<Path>>(&self, path: P) -> Result<()> {
        let path = path.as_ref();

        if !path.exists() {
            return Ok(());
        }

        // Skip snapshot-related paths
        if let Some(basename) = path.file_name() {
            let basename_str = basename.to_string_lossy();
            if basename_str == "@snapshots" || basename_str == ".snapshots" {
                debug!("Skipping snapshot directory: {:?}", path);
                return Ok(());
            }
        }

        // Check if this is actually a subvolume
        if !self.is_subvolume(path)? {
            warn!("{:?} is not a subvolume, skipping", path);
            return Ok(());
        }

        debug!("Processing subvolume for recursive deletion: {:?}", path);

        // Get child subvolumes
        let child_subvolumes = self.get_child_subvolumes(path)?;

        // Delete child subvolumes first
        for child in child_subvolumes {
            let child_path = self.mount_point.join(&child.path);

            // Skip snapshot-related child subvolumes
            if let Some(basename) = child_path.file_name() {
                let basename_str = basename.to_string_lossy();
                if basename_str == "@snapshots" || basename_str == ".snapshots" {
                    debug!("Skipping snapshot child subvolume: {:?}", child_path);
                    continue;
                }
            }

            debug!("Recursively deleting child subvolume: {:?}", child_path);
            self.delete_subvolume_recursively(&child_path)?;
        }

        // Clean non-subvolume contents
        if path.is_dir() {
            debug!("Cleaning non-subvolume contents from: {:?}", path);
            for entry in std::fs::read_dir(path)? {
                let entry = entry?;
                let entry_path = entry.path();

                if !self.is_subvolume(&entry_path)? {
                    debug!("Removing non-subvolume item: {:?}", entry_path);
                    if entry_path.is_dir() {
                        std::fs::remove_dir_all(&entry_path)
                            .unwrap_or_else(|e| warn!("Failed to remove directory {:?}: {}", entry_path, e));
                    } else {
                        std::fs::remove_file(&entry_path)
                            .unwrap_or_else(|e| warn!("Failed to remove file {:?}: {}", entry_path, e));
                    }
                }
            }
        }

        // Now try to delete the parent subvolume
        debug!("Attempting to delete now-empty subvolume: {:?}", path);
        let output = Command::new("btrfs")
            .args(["subvolume", "delete", path.to_str().unwrap()])
            .stdout(Stdio::piped())
            .stderr(Stdio::piped())
            .output()
            .context("Failed to delete subvolume")?;

        if !output.status.success() {
            let stderr = String::from_utf8_lossy(&output.stderr);
            warn!("Failed to delete {:?}: {}", path, stderr);
        }

        Ok(())
    }

    pub fn is_subvolume<P: AsRef<Path>>(&self, path: P) -> Result<bool> {
        let path = path.as_ref();

        let output = Command::new("btrfs")
            .args(["subvolume", "show", path.to_str().unwrap()])
            .stdout(Stdio::null())
            .stderr(Stdio::null())
            .output()
            .context("Failed to check if path is subvolume")?;

        Ok(output.status.success())
    }

    pub fn get_child_subvolumes<P: AsRef<Path>>(&self, path: P) -> Result<Vec<SubvolumeInfo>> {
        let path = path.as_ref();

        let output = Command::new("btrfs")
            .args(["subvolume", "list", "-o", path.to_str().unwrap()])
            .stdout(Stdio::piped())
            .stderr(Stdio::piped())
            .output()
            .context("Failed to list child subvolumes")?;

        if !output.status.success() {
            return Ok(Vec::new());
        }

        let stdout = String::from_utf8_lossy(&output.stdout);
        let mut subvolumes = Vec::new();

        for line in stdout.lines() {
            if let Some(info) = self.parse_subvolume_line(line) {
                subvolumes.push(info);
            }
        }

        Ok(subvolumes)
    }

    pub fn sync_filesystem<P: AsRef<Path>>(&self, path: P) -> Result<()> {
        let path = path.as_ref();

        let output = Command::new("btrfs")
            .args(["filesystem", "sync", path.to_str().unwrap()])
            .stdout(Stdio::piped())
            .stderr(Stdio::piped())
            .output()
            .context("Failed to sync filesystem")?;

        if !output.status.success() {
            let stderr = String::from_utf8_lossy(&output.stderr);
            warn!("Failed to sync filesystem: {}", stderr);
        }

        Ok(())
    }

    pub fn set_subvolume_readonly<P: AsRef<Path>>(&self, path: P, readonly: bool) -> Result<()> {
        let path = path.as_ref();
        let readonly_value = if readonly { "true" } else { "false" };

        let output = Command::new("btrfs")
            .args([
                "property", "set", "-ts",
                path.to_str().unwrap(),
                "ro",
                readonly_value,
            ])
            .stdout(Stdio::piped())
            .stderr(Stdio::piped())
            .output()
            .context("Failed to set subvolume readonly property")?;

        if !output.status.success() {
            let stderr = String::from_utf8_lossy(&output.stderr);
            anyhow::bail!("Failed to set readonly property: {}", stderr);
        }

        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::path::PathBuf;
    use tempfile::TempDir;

    fn create_test_manager() -> (BtrfsManager, TempDir) {
        let temp_dir = TempDir::new().unwrap();
        let mount_point = temp_dir.path().join("mount");
        let manager = BtrfsManager::new("/dev/fake", &mount_point);
        (manager, temp_dir)
    }

    #[test]
    fn test_new_manager() {
        let (manager, _temp_dir) = create_test_manager();
        assert_eq!(manager.device, PathBuf::from("/dev/fake"));
        assert!(manager.mount_point.to_string_lossy().contains("mount"));
    }

    #[test]
    fn test_parse_subvolume_line_valid() {
        let (manager, _temp_dir) = create_test_manager();
        let line = "ID 256 gen 85 top level 5 path @";
        let result = manager.parse_subvolume_line(line);

        assert!(result.is_some());
        let info = result.unwrap();
        assert_eq!(info.id, 256);
        assert_eq!(info.path, "@");
    }

    #[test]
    fn test_parse_subvolume_line_with_spaces() {
        let (manager, _temp_dir) = create_test_manager();
        let line = "ID 257 gen 84 top level 5 path @home with spaces";
        let result = manager.parse_subvolume_line(line);

        assert!(result.is_some());
        let info = result.unwrap();
        assert_eq!(info.id, 257);
        assert_eq!(info.path, "@home with spaces");
    }

    #[test]
    fn test_parse_subvolume_line_invalid() {
        let (manager, _temp_dir) = create_test_manager();
        let line = "invalid line format";
        let result = manager.parse_subvolume_line(line);
        assert!(result.is_none());
    }

    #[test]
    fn test_parse_subvolume_line_missing_id() {
        let (manager, _temp_dir) = create_test_manager();
        let line = "ID abc gen 85 top level 5 path @";
        let result = manager.parse_subvolume_line(line);
        assert!(result.is_none());
    }

    #[test]
    fn test_parse_subvolume_line_short() {
        let (manager, _temp_dir) = create_test_manager();
        let line = "ID 256 gen";
        let result = manager.parse_subvolume_line(line);
        assert!(result.is_none());
    }

    #[test]
    fn test_manager_paths() {
        let device = "/dev/test-device";
        let mount_point = "/tmp/test-mount";
        let manager = BtrfsManager::new(device, mount_point);

        assert_eq!(manager.device, PathBuf::from(device));
        assert_eq!(manager.mount_point, PathBuf::from(mount_point));
    }

    #[test]
    fn test_mount_subvolume_path_generation() {
        let (manager, _temp_dir) = create_test_manager();
        let subvolume_name = "@home";

        // This test doesn't actually mount, but tests path generation
        let expected_path = manager.mount_point.join(subvolume_name);
        assert!(expected_path.to_string_lossy().contains("@home"));
    }

    #[test]
    fn test_parse_multiple_subvolume_lines() {
        let (manager, _temp_dir) = create_test_manager();
        let lines = vec![
            "ID 256 gen 85 top level 5 path @",
            "ID 257 gen 84 top level 5 path @home",
            "invalid line",
            "ID 258 gen 83 top level 5 path @snapshots",
        ];

        let mut results = Vec::new();
        for line in lines {
            if let Some(info) = manager.parse_subvolume_line(line) {
                results.push(info);
            }
        }

        assert_eq!(results.len(), 3);
        assert_eq!(results[0].path, "@");
        assert_eq!(results[1].path, "@home");
        assert_eq!(results[2].path, "@snapshots");
    }

    #[test]
    fn test_subvolume_info_debug() {
        let info = SubvolumeInfo {
            id: 256,
            path: "@test".to_string(),
        };
        let debug_str = format!("{:?}", info);
        assert!(debug_str.contains("256"));
        assert!(debug_str.contains("@test"));
    }

    #[test]
    fn test_manager_clone_subvolume_info() {
        let info = SubvolumeInfo {
            id: 256,
            path: "@test".to_string(),
        };
        let cloned = info.clone();
        assert_eq!(cloned.id, info.id);
        assert_eq!(cloned.path, info.path);
    }

    // Mock tests that don't require actual btrfs commands
    mod mock_tests {
        use super::*;

        #[test]
        fn test_parse_edge_cases() {
            let (manager, _temp_dir) = create_test_manager();

            // Test empty line
            assert!(manager.parse_subvolume_line("").is_none());

            // Test line with just ID
            assert!(manager.parse_subvolume_line("ID").is_none());

            // Test line without path keyword
            assert!(manager.parse_subvolume_line("ID 256 gen 85 top level 5").is_none());

            // Test line with path but no actual path value
            assert!(manager.parse_subvolume_line("ID 256 gen 85 top level 5 path").is_none());
        }

        #[test]
        fn test_device_and_mount_point_types() {
            // Test with different path types
            let manager1 = BtrfsManager::new("/dev/sda1", "/mnt/test");
            let manager2 = BtrfsManager::new(PathBuf::from("/dev/sda2"), PathBuf::from("/mnt/test2"));
            let manager3 = BtrfsManager::new(String::from("/dev/sda3"), String::from("/mnt/test3"));

            assert_eq!(manager1.device, PathBuf::from("/dev/sda1"));
            assert_eq!(manager2.device, PathBuf::from("/dev/sda2"));
            assert_eq!(manager3.device, PathBuf::from("/dev/sda3"));
        }
    }
}