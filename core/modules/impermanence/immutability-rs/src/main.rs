use anyhow::{Context, Result};
use chrono::Utc;
use clap::Parser;
use log::{debug, error, info};
use std::collections::HashMap;
use std::path::PathBuf;
use std::time::Instant;

mod btrfs;
mod fileops;

#[cfg(test)]
mod test_utils;

use btrfs::BtrfsManager;
use fileops::FileOperations;

#[derive(Parser, Debug)]
#[command(name = "immutability")]
#[command(about = "Fast BTRFS impermanence manager")]
#[command(version)]
struct Args {
    /// Block device (e.g., /dev/disk/by-label/nixos)
    device: String,

    /// Snapshots subvolume name (e.g., @snapshots)
    snapshots_subvolume: String,

    /// Subvolume pairs (e.g., "@=/", "@home=/home")
    subvolume_pairs: String,

    /// Paths to keep separated by spaces
    paths_to_keep: String,
}

#[derive(Debug, Clone)]
struct SubvolumePair {
    name: String,
    mount_point: PathBuf,
}

struct ImmutabilityManager {
    btrfs: BtrfsManager,
    fileops: FileOperations,
    snapshots_subvolume: String,
    subvolume_pairs: Vec<SubvolumePair>,
    paths_to_keep: Vec<String>,
}

impl ImmutabilityManager {
    fn new(args: Args) -> Result<Self> {
        let mount_point = PathBuf::from("/tmp/btrfs-immutable");
        let btrfs = BtrfsManager::new(&args.device, &mount_point);
        let fileops = FileOperations::new();

        // Parse subvolume pairs
        let subvolume_pairs = Self::parse_subvolume_pairs(&args.subvolume_pairs)?;

        // Parse paths to keep
        let paths_to_keep = Self::parse_paths_to_keep(&args.paths_to_keep);

        debug!("Parsed subvolume pairs: {:?}", subvolume_pairs);
        debug!("Paths to keep: {:?}", paths_to_keep);

        Ok(Self {
            btrfs,
            fileops,
            snapshots_subvolume: args.snapshots_subvolume,
            subvolume_pairs,
            paths_to_keep,
        })
    }

    fn parse_subvolume_pairs(pairs_str: &str) -> Result<Vec<SubvolumePair>> {
        let mut pairs = Vec::new();

        for pair in pairs_str.split_whitespace() {
            if pair.is_empty() {
                continue;
            }
            if let Some((name, mount_point)) = pair.split_once('=') {
                if name.is_empty() || mount_point.is_empty() {
                    anyhow::bail!("Invalid subvolume pair format: {}", pair);
                }
                pairs.push(SubvolumePair {
                    name: name.to_string(),
                    mount_point: PathBuf::from(mount_point),
                });
            } else {
                anyhow::bail!("Invalid subvolume pair format: {}", pair);
            }
        }

        if pairs.is_empty() {
            anyhow::bail!("No subvolume pairs specified");
        }

        Ok(pairs)
    }

    fn parse_paths_to_keep(paths_str: &str) -> Vec<String> {
        paths_str
            .split_whitespace()
            .map(|s| s.to_string())
            .filter(|s| !s.is_empty())
            .collect()
    }

    fn run(&mut self) -> Result<()> {
        let start_time = Instant::now();
        info!("Starting BTRFS impermanence reset");
        info!("Processing subvolumes: {:?}",
              self.subvolume_pairs.iter().map(|p| &p.name).collect::<Vec<_>>());
        info!("Preserving {} paths", self.paths_to_keep.len());

        // Mount the root filesystem
        self.btrfs.mount_root()
            .context("Failed to mount root filesystem")?;

        // List and validate subvolumes
        self.validate_subvolumes()?;

        // Mount all required subvolumes
        self.mount_subvolumes()?;

        // Process each subvolume
        for pair in &self.subvolume_pairs {
            self.process_subvolume(pair)
                .with_context(|| format!("Failed to process subvolume {}", pair.name))?;
        }

        // Cleanup
        self.btrfs.unmount()
            .context("Failed to unmount filesystem")?;

        let duration = start_time.elapsed();
        let (files, dirs, bytes) = self.fileops.get_stats();

        info!("BTRFS impermanence reset completed successfully");
        info!("Processed {} files, {} directories, {} bytes in {:.2}s",
              files, dirs, bytes, duration.as_secs_f64());

        Ok(())
    }

    fn validate_subvolumes(&self) -> Result<()> {
        debug!("Validating subvolumes exist");

        let subvolumes = self.btrfs.list_subvolumes()
            .context("Failed to list subvolumes")?;

        let available_subvolumes: HashMap<String, _> = subvolumes
            .into_iter()
            .map(|s| (s.path.clone(), s))
            .collect();

        // Check that required subvolumes exist
        for pair in &self.subvolume_pairs {
            if !available_subvolumes.contains_key(&pair.name) {
                anyhow::bail!("Required subvolume {} not found", pair.name);
            }
        }

        // Check that snapshots subvolume exists
        if !available_subvolumes.contains_key(&self.snapshots_subvolume) {
            anyhow::bail!("Snapshots subvolume {} not found", self.snapshots_subvolume);
        }

        debug!("All required subvolumes found");
        Ok(())
    }

    fn mount_subvolumes(&self) -> Result<()> {
        debug!("Mounting subvolumes");

        // Mount all subvolumes including snapshots
        let mut subvolume_names: Vec<String> = self.subvolume_pairs
            .iter()
            .map(|p| p.name.clone())
            .collect();
        subvolume_names.push(self.snapshots_subvolume.clone());

        for subvolume_name in subvolume_names {
            self.btrfs.mount_subvolume(&subvolume_name)
                .with_context(|| format!("Failed to mount subvolume {}", subvolume_name))?;
        }

        debug!("All subvolumes mounted successfully");
        Ok(())
    }

    fn process_subvolume(&self, pair: &SubvolumePair) -> Result<()> {
        let subvolume_start = Instant::now();
        info!("Processing subvolume: {}", pair.name);

        let subvolume_path = self.btrfs.mount_point.join(&pair.name);
        let snapshots_dir = self.btrfs.mount_point
            .join(&self.snapshots_subvolume)
            .join(&pair.name);
        let fresh_snapshot = snapshots_dir.join("FRESH");

        // Ensure snapshots directory exists
        std::fs::create_dir_all(&snapshots_dir)
            .context("Failed to create snapshots directory")?;

        // Clean up any existing FRESH snapshot
        if fresh_snapshot.exists() {
            info!("Cleaning up existing FRESH snapshot");
            self.btrfs.delete_subvolume_recursively(&fresh_snapshot)?;
        }

        // Create fresh empty subvolume
        info!("Creating fresh empty subvolume");
        std::fs::create_dir_all(fresh_snapshot.parent().unwrap())
            .context("Failed to create parent directory for fresh snapshot")?;
        self.btrfs.create_subvolume(&fresh_snapshot)
            .context("Failed to create fresh subvolume")?;

        // Extract persistent files directly to the fresh subvolume
        info!("Extracting persistent files to fresh subvolume");
        self.fileops.extract_persistent_files(
            &pair.mount_point,
            &self.paths_to_keep,
            &subvolume_path,
            &fresh_snapshot,
        ).context("Failed to extract persistent files")?;

        // Clear contents of current subvolume while preserving structure
        info!("Clearing subvolume contents while preserving structure");
        self.fileops.clear_subvolume_contents(
            &subvolume_path,
            &self.paths_to_keep,
            &self.btrfs,
        ).context("Failed to clear subvolume contents")?;

        // Copy fresh contents to cleared subvolume
        info!("Copying fresh contents to cleared subvolume");
        self.fileops.copy_persistent_files_fast(&fresh_snapshot, &subvolume_path)
            .context("Failed to copy persistent files")?;

        // Clean up the fresh snapshot
        self.btrfs.delete_subvolume(&fresh_snapshot)
            .context("Failed to delete fresh snapshot")?;

        let duration = subvolume_start.elapsed();
        info!("Completed processing {} in {:.2}s", pair.name, duration.as_secs_f64());

        Ok(())
    }
}

fn setup_logging() -> Result<()> {
    env_logger::Builder::from_default_env()
        .format_timestamp_millis()
        .init();
    Ok(())
}

fn main() -> Result<()> {
    setup_logging()?;

    let args = Args::parse();

    info!("=== IMMUTABILITY SERVICE RUST VERSION - {} ===", Utc::now().format("%c"));
    info!("Arguments: device={}, snapshots={}, pairs={}, paths_count={}",
          args.device, args.snapshots_subvolume, args.subvolume_pairs,
          args.paths_to_keep.split_whitespace().count());

    let mut manager = ImmutabilityManager::new(args)
        .context("Failed to initialize immutability manager")?;

    if let Err(e) = manager.run() {
        error!("Immutability reset failed: {:?}", e);

        // Attempt cleanup on error
        if let Err(cleanup_err) = manager.btrfs.unmount() {
            error!("Failed to cleanup after error: {:?}", cleanup_err);
        }

        std::process::exit(1);
    }

    info!("=== IMMUTABILITY SERVICE COMPLETED SUCCESSFULLY - {} ===", Utc::now().format("%c"));
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_parse_subvolume_pairs_valid() {
        let pairs_str = "@=/ @home=/home @var=/var";
        let result = ImmutabilityManager::parse_subvolume_pairs(pairs_str).unwrap();

        assert_eq!(result.len(), 3);
        assert_eq!(result[0].name, "@");
        assert_eq!(result[0].mount_point, PathBuf::from("/"));
        assert_eq!(result[1].name, "@home");
        assert_eq!(result[1].mount_point, PathBuf::from("/home"));
        assert_eq!(result[2].name, "@var");
        assert_eq!(result[2].mount_point, PathBuf::from("/var"));
    }

    #[test]
    fn test_parse_subvolume_pairs_single() {
        let pairs_str = "@=/";
        let result = ImmutabilityManager::parse_subvolume_pairs(pairs_str).unwrap();

        assert_eq!(result.len(), 1);
        assert_eq!(result[0].name, "@");
        assert_eq!(result[0].mount_point, PathBuf::from("/"));
    }

    #[test]
    fn test_parse_subvolume_pairs_with_complex_names() {
        let pairs_str = "@my-vol=/mnt/my-vol";
        let result = ImmutabilityManager::parse_subvolume_pairs(pairs_str).unwrap();

        assert_eq!(result.len(), 1);
        assert_eq!(result[0].name, "@my-vol");
        assert_eq!(result[0].mount_point, PathBuf::from("/mnt/my-vol"));
    }

    #[test]
    fn test_parse_subvolume_pairs_invalid_format() {
        let pairs_str = "invalid_no_equals";
        let result = ImmutabilityManager::parse_subvolume_pairs(pairs_str);

        assert!(result.is_err());
        assert!(result.unwrap_err().to_string().contains("Invalid subvolume pair format"));
    }

    #[test]
    fn test_parse_subvolume_pairs_empty() {
        let pairs_str = "";
        let result = ImmutabilityManager::parse_subvolume_pairs(pairs_str);

        assert!(result.is_err());
        assert!(result.unwrap_err().to_string().contains("No subvolume pairs specified"));
    }

    #[test]
    fn test_parse_subvolume_pairs_whitespace_only() {
        let pairs_str = "   \t\n  ";
        let result = ImmutabilityManager::parse_subvolume_pairs(pairs_str);

        assert!(result.is_err());
        assert!(result.unwrap_err().to_string().contains("No subvolume pairs specified"));
    }

    #[test]
    fn test_parse_subvolume_pairs_mixed_valid_invalid() {
        let pairs_str = "@=/ invalid_format @home=/home";
        let result = ImmutabilityManager::parse_subvolume_pairs(pairs_str);

        assert!(result.is_err());
        assert!(result.unwrap_err().to_string().contains("Invalid subvolume pair format"));
    }

    #[test]
    fn test_parse_paths_to_keep_multiple() {
        let paths_str = "/etc/ssh /etc/sops /var/log /var/lib/nixos";
        let result = ImmutabilityManager::parse_paths_to_keep(paths_str);

        assert_eq!(result.len(), 4);
        assert_eq!(result[0], "/etc/ssh");
        assert_eq!(result[1], "/etc/sops");
        assert_eq!(result[2], "/var/log");
        assert_eq!(result[3], "/var/lib/nixos");
    }

    #[test]
    fn test_parse_paths_to_keep_single() {
        let paths_str = "/etc/ssh";
        let result = ImmutabilityManager::parse_paths_to_keep(paths_str);

        assert_eq!(result.len(), 1);
        assert_eq!(result[0], "/etc/ssh");
    }

    #[test]
    fn test_parse_paths_to_keep_empty() {
        let paths_str = "";
        let result = ImmutabilityManager::parse_paths_to_keep(paths_str);

        assert_eq!(result.len(), 0);
    }

    #[test]
    fn test_parse_paths_to_keep_whitespace() {
        let paths_str = "  /etc/ssh   /var/log  ";
        let result = ImmutabilityManager::parse_paths_to_keep(paths_str);

        assert_eq!(result.len(), 2);
        assert_eq!(result[0], "/etc/ssh");
        assert_eq!(result[1], "/var/log");
    }

    #[test]
    fn test_parse_paths_to_keep_with_empty_entries() {
        let paths_str = "/etc/ssh  /var/log";
        let result = ImmutabilityManager::parse_paths_to_keep(paths_str);

        // Empty entries should be filtered out
        assert_eq!(result.len(), 2);
        assert_eq!(result[0], "/etc/ssh");
        assert_eq!(result[1], "/var/log");
    }

    #[test]
    fn test_subvolume_pair_debug() {
        let pair = SubvolumePair {
            name: "@test".to_string(),
            mount_point: PathBuf::from("/test"),
        };

        let debug_str = format!("{:?}", pair);
        assert!(debug_str.contains("@test"));
        assert!(debug_str.contains("/test"));
    }

    #[test]
    fn test_subvolume_pair_clone() {
        let pair = SubvolumePair {
            name: "@original".to_string(),
            mount_point: PathBuf::from("/original"),
        };

        let cloned = pair.clone();
        assert_eq!(cloned.name, pair.name);
        assert_eq!(cloned.mount_point, pair.mount_point);
    }

    #[test]
    fn test_args_debug() {
        let args = Args {
            device: "/dev/test".to_string(),
            snapshots_subvolume: "@snapshots".to_string(),
            subvolume_pairs: "@=/".to_string(),
            paths_to_keep: "/etc/ssh".to_string(),
        };

        let debug_str = format!("{:?}", args);
        assert!(debug_str.contains("/dev/test"));
        assert!(debug_str.contains("@snapshots"));
    }

    // Test error handling in parsing functions
    mod error_handling_tests {
        use super::*;

        #[test]
        fn test_parse_subvolume_pairs_multiple_invalid() {
            let test_cases = vec![
                "no_equals_sign",
                "missing_mount=",
                "@valid=/ invalid_format @another=/path",
            ];

            for case in test_cases {
                let result = ImmutabilityManager::parse_subvolume_pairs(case);
                assert!(result.is_err(), "Expected error for case: {}", case);
            }
        }

        #[test]
        fn test_parse_subvolume_pairs_edge_cases() {
            // Test various edge cases
            assert!(ImmutabilityManager::parse_subvolume_pairs("=").is_err());
            assert!(ImmutabilityManager::parse_subvolume_pairs("==").is_err());
            assert!(ImmutabilityManager::parse_subvolume_pairs("a=").is_err());
            assert!(ImmutabilityManager::parse_subvolume_pairs("=b").is_err());
        }

        #[test]
        fn test_parse_subvolume_pairs_empty_parts() {
            // Test cases with empty name or mount point
            assert!(ImmutabilityManager::parse_subvolume_pairs("=missing_name").is_err());
            assert!(ImmutabilityManager::parse_subvolume_pairs("missing_mount=").is_err());
        }
    }

    // Test the argument parsing structure
    mod args_tests {
        use super::*;

        #[test]
        fn test_args_creation() {
            let args = Args {
                device: "/dev/sda1".to_string(),
                snapshots_subvolume: "@snapshots".to_string(),
                subvolume_pairs: "@=/ @home=/home".to_string(),
                paths_to_keep: "/etc/ssh /var/log".to_string(),
            };

            assert_eq!(args.device, "/dev/sda1");
            assert_eq!(args.snapshots_subvolume, "@snapshots");
            assert_eq!(args.subvolume_pairs, "@=/ @home=/home");
            assert_eq!(args.paths_to_keep, "/etc/ssh /var/log");
        }
    }

    // Tests using the test utilities
    mod integration_tests_with_mocks {
        use super::*;
        use crate::test_utils::{assertions::*, mocks::*};

        #[test]
        fn test_parse_subvolume_pairs_with_mock_data() {
            let mock_pairs = mock_subvolume_paths();
            let pairs_str = mock_pairs.iter()
                .map(|(name, path)| format!("{}={}", name, path.display()))
                .collect::<Vec<_>>()
                .join(" ");

            let result = ImmutabilityManager::parse_subvolume_pairs(&pairs_str).unwrap();

            assert_eq!(result.len(), mock_pairs.len());
            for (i, (expected_name, expected_path)) in mock_pairs.iter().enumerate() {
                assert_eq!(result[i].name, *expected_name);
                assert_eq!(result[i].mount_point, *expected_path);
            }
        }

        #[test]
        fn test_parse_paths_to_keep_with_mock_data() {
            let mock_paths = mock_paths_to_keep();
            let paths_str = mock_paths.join(" ");

            let result = ImmutabilityManager::parse_paths_to_keep(&paths_str);

            assert_vec_equivalent(&result, &mock_paths);
        }

        #[test]
        fn test_error_handling_with_invalid_mock_data() {
            // Test with intentionally broken data
            let invalid_pairs = "@=/ broken_format @home=/home";
            assert_error_contains(
                ImmutabilityManager::parse_subvolume_pairs(invalid_pairs),
                "Invalid subvolume pair format"
            );

            let empty_pairs = "";
            assert_error_contains(
                ImmutabilityManager::parse_subvolume_pairs(empty_pairs),
                "No subvolume pairs specified"
            );
        }

        #[test]
        fn test_mock_device_and_mount_point_paths() {
            let device = mock_device_path();
            let mount = mock_mount_point();

            assert_path_contains(&device, "/dev/");
            assert_path_contains(&mount, "/tmp/");

            // These paths should be safe mock paths that don't exist
            assert!(!std::path::Path::new(&device).exists());
        }

        #[test]
        fn test_subvolume_pair_creation_with_mock_data() {
            let mock_pairs = mock_subvolume_paths();

            for (name, path) in mock_pairs {
                let pair = SubvolumePair {
                    name: name.clone(),
                    mount_point: path.clone(),
                };

                assert_eq!(pair.name, name);
                assert_eq!(pair.mount_point, path);
            }
        }

        #[test]
        fn test_complex_parsing_scenarios() {
            // Test with realistic data from the actual system
            let complex_pairs = "@=/ @home=/home @var=/var @nix=/nix @snapshots=/snapshots";
            let result = ImmutabilityManager::parse_subvolume_pairs(complex_pairs).unwrap();

            assert_eq!(result.len(), 5);
            assert_eq!(result[0].name, "@");
            assert_eq!(result[0].mount_point, PathBuf::from("/"));
            assert_eq!(result[1].name, "@home");
            assert_eq!(result[1].mount_point, PathBuf::from("/home"));
            assert_eq!(result[4].name, "@snapshots");
            assert_eq!(result[4].mount_point, PathBuf::from("/snapshots"));

            // Test with complex paths to keep
            let complex_paths = "/etc/ssh /etc/sops /var/log /var/lib/nixos /var/lib/systemd/random-seed /home/user/.config /home/user/.ssh";
            let paths_result = ImmutabilityManager::parse_paths_to_keep(complex_paths);

            assert_eq!(paths_result.len(), 7);
            assert!(paths_result.contains(&"/etc/ssh".to_string()));
            assert!(paths_result.contains(&"/home/user/.config".to_string()));
            assert!(paths_result.contains(&"/var/lib/systemd/random-seed".to_string()));
        }
    }
}