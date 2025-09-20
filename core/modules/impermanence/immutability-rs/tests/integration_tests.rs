use assert_cmd::prelude::*;
use predicates::prelude::*;
use std::process::Command;

// These tests only check argument parsing and help output
// They DO NOT perform any actual filesystem operations

#[test]
fn test_help_command() {
    let mut cmd = Command::cargo_bin("immutability").unwrap();
    cmd.arg("--help");

    cmd.assert()
        .success()
        .stdout(predicate::str::contains("Fast BTRFS impermanence manager"));
}

#[test]
fn test_version_command() {
    let mut cmd = Command::cargo_bin("immutability").unwrap();
    cmd.arg("--version");

    cmd.assert()
        .success()
        .stdout(predicate::str::contains("immutability"));
}

#[test]
fn test_missing_arguments() {
    let mut cmd = Command::cargo_bin("immutability").unwrap();

    cmd.assert()
        .failure()
        .stderr(predicate::str::contains("required"));
}

#[test]
fn test_invalid_subvolume_pairs_format() {
    let mut cmd = Command::cargo_bin("immutability").unwrap();
    cmd.args([
        "/dev/fake",  // This won't be accessed due to early validation failure
        "@snapshots",
        "invalid_format_no_equals",  // This should cause parsing to fail early
        "/etc/ssh",
    ]);

    // Should fail due to invalid subvolume pair format before any filesystem operations
    cmd.assert()
        .failure()
        .stderr(predicate::str::contains("Invalid subvolume pair format"));
}

#[test]
fn test_empty_subvolume_pairs() {
    let mut cmd = Command::cargo_bin("immutability").unwrap();
    cmd.args([
        "/dev/fake",  // This won't be accessed due to early validation failure
        "@snapshots",
        "",  // Empty pairs should cause early failure
        "/etc/ssh",
    ]);

    // Should fail due to no subvolume pairs before any filesystem operations
    cmd.assert()
        .failure()
        .stderr(predicate::str::contains("No subvolume pairs specified"));
}

// Test that the binary exists and can be executed
#[test]
fn test_binary_exists() {
    let mut cmd = Command::cargo_bin("immutability").unwrap();
    cmd.arg("--help");

    // Just checking the binary can be found and executed
    cmd.assert().success();
}

// Test argument count validation (should fail before any FS operations)
#[test]
fn test_insufficient_arguments() {
    let mut cmd = Command::cargo_bin("immutability").unwrap();
    cmd.args(["/dev/fake", "@snapshots"]);  // Missing required args

    cmd.assert()
        .failure()
        .stderr(predicate::str::contains("required"));
}

// Test help flag takes precedence (no FS operations)
#[test]
fn test_help_flag_precedence() {
    let mut cmd = Command::cargo_bin("immutability").unwrap();
    cmd.args(["--help", "/dev/fake", "@snapshots", "@=/", "/etc/ssh"]);

    // Help should work even with other args
    cmd.assert()
        .success()
        .stdout(predicate::str::contains("Fast BTRFS impermanence manager"));
}