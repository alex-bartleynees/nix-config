//! Test utilities for the immutability project
//!
//! This module provides utilities for testing that do NOT interact with the real filesystem
//! or execute any actual BTRFS commands. All operations are mocked and safe.

#[cfg(test)]
pub mod mocks {
    use crate::btrfs::SubvolumeInfo;
    use std::path::PathBuf;
    use tempfile::TempDir;

    /// Creates a mock BTRFS output for testing subvolume parsing
    pub fn mock_btrfs_list_output() -> String {
        r#"ID 256 gen 85 top level 5 path @
ID 257 gen 84 top level 5 path @home
ID 258 gen 83 top level 5 path @nix
ID 259 gen 12 top level 5 path @snapshots
ID 260 gen 82 top level 257 path @home/.snapshots
ID 261 gen 82 top level 256 path @/srv
ID 262 gen 82 top level 256 path @/var/lib/portables
ID 263 gen 82 top level 256 path @/var/lib/machines
ID 264 gen 83 top level 256 path @/tmp
ID 265 gen 82 top level 256 path @/var/tmp"#.to_string()
    }

    /// Creates a mock BTRFS output with edge cases for testing
    pub fn mock_btrfs_list_output_with_edge_cases() -> String {
        r#"ID 256 gen 85 top level 5 path @
ID 257 gen 84 top level 5 path @home with spaces
ID 258 gen 83 top level 5 path @special-chars_123
invalid line without proper format
ID 259 gen 12 top level 5 path @snapshots
ID abc gen 85 top level 5 path @invalid_id"#.to_string()
    }

    /// Creates expected SubvolumeInfo results for the mock output
    pub fn expected_subvolume_infos() -> Vec<SubvolumeInfo> {
        vec![
            SubvolumeInfo { id: 256, path: "@".to_string() },
            SubvolumeInfo { id: 257, path: "@home".to_string() },
            SubvolumeInfo { id: 258, path: "@nix".to_string() },
            SubvolumeInfo { id: 259, path: "@snapshots".to_string() },
            SubvolumeInfo { id: 260, path: "@home/.snapshots".to_string() },
            SubvolumeInfo { id: 261, path: "@/srv".to_string() },
            SubvolumeInfo { id: 262, path: "@/var/lib/portables".to_string() },
            SubvolumeInfo { id: 263, path: "@/var/lib/machines".to_string() },
            SubvolumeInfo { id: 264, path: "@/tmp".to_string() },
            SubvolumeInfo { id: 265, path: "@/var/tmp".to_string() },
        ]
    }

    /// Creates a temporary directory structure for testing file operations
    pub fn create_mock_file_structure() -> Result<TempDir, std::io::Error> {
        let temp_dir = TempDir::new()?;
        let base = temp_dir.path();

        // Create directory structure
        std::fs::create_dir_all(base.join("etc/ssh"))?;
        std::fs::create_dir_all(base.join("etc/sops"))?;
        std::fs::create_dir_all(base.join("var/log"))?;
        std::fs::create_dir_all(base.join("var/lib/nixos"))?;
        std::fs::create_dir_all(base.join("home/user/.config"))?;

        // Create some test files
        std::fs::write(base.join("etc/ssh/ssh_host_rsa_key"), "fake ssh key")?;
        std::fs::write(base.join("etc/ssh/ssh_host_rsa_key.pub"), "fake ssh public key")?;
        std::fs::write(base.join("var/log/system.log"), "fake log content")?;
        std::fs::write(base.join("home/user/.config/app.conf"), "user config")?;

        Ok(temp_dir)
    }

    /// Creates a mock subvolume paths for testing path resolution
    pub fn mock_subvolume_paths() -> Vec<(String, PathBuf)> {
        vec![
            ("@".to_string(), PathBuf::from("/")),
            ("@home".to_string(), PathBuf::from("/home")),
            ("@var".to_string(), PathBuf::from("/var")),
            ("@tmp".to_string(), PathBuf::from("/tmp")),
        ]
    }

    /// Creates mock paths to keep for testing
    pub fn mock_paths_to_keep() -> Vec<String> {
        vec![
            "/etc/ssh".to_string(),
            "/etc/sops".to_string(),
            "/var/log".to_string(),
            "/var/lib/nixos".to_string(),
            "/home/user/.config".to_string(),
        ]
    }

    /// Mock device path that won't actually be accessed
    pub fn mock_device_path() -> String {
        "/dev/mock-device".to_string()
    }

    /// Mock mount point that won't actually be created
    pub fn mock_mount_point() -> PathBuf {
        PathBuf::from("/tmp/mock-btrfs-mount")
    }

    #[cfg(test)]
    mod tests {
        use super::*;

        #[test]
        fn test_mock_btrfs_output_is_valid() {
            let output = mock_btrfs_list_output();
            assert!(output.contains("ID 256"));
            assert!(output.contains("path @"));
            assert!(output.contains("@home"));
        }

        #[test]
        fn test_expected_subvolume_infos() {
            let infos = expected_subvolume_infos();
            assert_eq!(infos.len(), 10);
            assert_eq!(infos[0].id, 256);
            assert_eq!(infos[0].path, "@");
        }

        #[test]
        fn test_create_mock_file_structure() {
            let temp_dir = create_mock_file_structure().unwrap();
            let base = temp_dir.path();

            assert!(base.join("etc/ssh").exists());
            assert!(base.join("etc/ssh/ssh_host_rsa_key").exists());
            assert!(base.join("var/log/system.log").exists());
            assert!(base.join("home/user/.config/app.conf").exists());
        }

        #[test]
        fn test_mock_subvolume_paths() {
            let paths = mock_subvolume_paths();
            assert_eq!(paths.len(), 4);
            assert_eq!(paths[0].0, "@");
            assert_eq!(paths[0].1, PathBuf::from("/"));
            assert_eq!(paths[1].0, "@home");
            assert_eq!(paths[1].1, PathBuf::from("/home"));
        }

        #[test]
        fn test_mock_paths_to_keep() {
            let paths = mock_paths_to_keep();
            assert_eq!(paths.len(), 5);
            assert!(paths.contains(&"/etc/ssh".to_string()));
            assert!(paths.contains(&"/home/user/.config".to_string()));
        }

        #[test]
        fn test_mock_device_and_mount_paths() {
            let device = mock_device_path();
            let mount = mock_mount_point();

            assert_eq!(device, "/dev/mock-device");
            assert_eq!(mount, PathBuf::from("/tmp/mock-btrfs-mount"));
        }
    }
}

#[cfg(test)]
pub mod assertions {
    use std::path::Path;

    /// Asserts that a path contains the expected substring
    pub fn assert_path_contains<P: AsRef<Path>>(path: P, expected: &str) {
        let path_str = path.as_ref().to_string_lossy();
        assert!(
            path_str.contains(expected),
            "Path '{}' does not contain '{}'",
            path_str,
            expected
        );
    }

    /// Asserts that a result is an error and contains the expected message
    pub fn assert_error_contains<T, E: std::fmt::Display>(
        result: Result<T, E>,
        expected_message: &str,
    ) {
        match result {
            Ok(_) => panic!("Expected error but got Ok result"),
            Err(e) => {
                let error_str = e.to_string();
                assert!(
                    error_str.contains(expected_message),
                    "Error '{}' does not contain '{}'",
                    error_str,
                    expected_message
                );
            }
        }
    }

    /// Asserts that a vector contains all expected elements
    pub fn assert_vec_contains_all<T: PartialEq + std::fmt::Debug>(
        vec: &[T],
        expected: &[T],
    ) {
        for item in expected {
            assert!(
                vec.contains(item),
                "Vector {:?} does not contain {:?}",
                vec,
                item
            );
        }
    }

    /// Asserts that two vectors have the same length and elements (order-independent)
    pub fn assert_vec_equivalent<T: PartialEq + std::fmt::Debug>(
        actual: &[T],
        expected: &[T],
    ) {
        assert_eq!(
            actual.len(),
            expected.len(),
            "Vectors have different lengths: actual={:?}, expected={:?}",
            actual,
            expected
        );
        assert_vec_contains_all(actual, expected);
        assert_vec_contains_all(expected, actual);
    }

    #[cfg(test)]
    mod tests {
        use super::*;
        use std::path::PathBuf;

        #[test]
        fn test_assert_path_contains() {
            let path = PathBuf::from("/home/user/.config");
            assert_path_contains(&path, "user");
            assert_path_contains(&path, ".config");
        }

        #[test]
        #[should_panic]
        fn test_assert_path_contains_fail() {
            let path = PathBuf::from("/home/user");
            assert_path_contains(&path, "nonexistent");
        }

        #[test]
        fn test_assert_error_contains() {
            let result: Result<(), String> = Err("Invalid format".to_string());
            assert_error_contains(result, "Invalid");
        }

        #[test]
        #[should_panic]
        fn test_assert_error_contains_with_ok() {
            let result: Result<i32, String> = Ok(42);
            assert_error_contains(result, "Invalid");
        }

        #[test]
        fn test_assert_vec_contains_all() {
            let vec = vec![1, 2, 3, 4];
            let expected = vec![2, 4];
            assert_vec_contains_all(&vec, &expected);
        }

        #[test]
        fn test_assert_vec_equivalent() {
            let vec1 = vec![1, 2, 3];
            let vec2 = vec![3, 1, 2];
            assert_vec_equivalent(&vec1, &vec2);
        }
    }
}