#!/bin/bash
set -euo pipefail

# Helper script to run test.sh with the same arguments as configured in impermanence.nix
# This allows testing the impermanence script outside of the boot process

# Arguments extracted from core/modules/impermanence.nix and hosts/thinkpad/nixos/configuration.nix
DEVICE="/dev/disk/by-label/nixos"
SNAPSHOTS_SUBVOLUME="@snapshots"
SUBVOLUME_PAIRS="@=/"
PATHS_TO_KEEP="/etc/sops /etc/ssh /etc/machine-id /etc/hostname-for-rebuild /var/log /var/lib/nixos /var/lib/systemd/random-seed /var/lib/systemd/coredump /var/lib/systemd/timers /var/lib/tailscale /var/lib/bluetooth /var/lib/colord /var/lib/docker /etc/NetworkManager/system-connections /etc/shadow /etc/passwd /etc/group /etc/gshadow /home/alexbn/.ssh /home/alexbn/.gnupg /home/alexbn/.vscode /home/alexbn/.config/JetBrains /home/alexbn/.local/share/JetBrains /home/alexbn/.dotnet /home/alexbn/.nuget /home/alexbn/.config/BraveSoftware /home/alexbn/.mozilla /home/alexbn/.local/share/obsidian /home/alexbn/Documents /home/alexbn/Downloads /home/alexbn/Pictures /home/alexbn/workspaces /home/alexbn/.config/nix-config /home/alexbn/.config/nix-devenv /home/alexbn/.config/nixos-secrets /home/alexbn/.config/dotfiles /home/alexbn/.config/sops /home/alexbn/.gitconfig /home/alexbn/.config/git /home/alexbn/.zsh_history /home/alexbn/.bash_history /home/alexbn/.p10k.zsh /home/alexbn/.local/share/atuin /home/alexbn/.local/share/zoxide /home/alexbn/.config/direnv /home/alexbn/.tmux /home/alexbn/.config/tmuxinator /home/alexbn/.local/share/nvim /home/alexbn/.cache/nvim /home/alexbn/.config/yazi /home/alexbn/.local/share/applications"

# Script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_SCRIPT="$SCRIPT_DIR/test.sh"

# Verify test.sh exists
if [[ ! -f "$TEST_SCRIPT" ]]; then
    echo "Error: test.sh not found at $TEST_SCRIPT"
    exit 1
fi

# Make test.sh executable if it isn't already
if [[ ! -x "$TEST_SCRIPT" ]]; then
    echo "Making test.sh executable..."
    chmod +x "$TEST_SCRIPT"
fi

echo "=========================================="
echo "Testing impermanence script with arguments:"
echo "Device: $DEVICE"
echo "Snapshots subvolume: $SNAPSHOTS_SUBVOLUME"
echo "Subvolume pairs: $SUBVOLUME_PAIRS"
echo "Number of paths to keep: $(echo "$PATHS_TO_KEEP" | wc -w)"
echo "=========================================="

# Check if running as root (required for BTRFS operations)
if [[ $EUID -ne 0 ]]; then
    echo "Warning: This script typically needs to run as root for BTRFS operations."
    echo "You may want to run: sudo $0"
    echo ""
fi

# Check if the device exists
if [[ ! -e "$DEVICE" ]]; then
    echo "Warning: Device $DEVICE does not exist."
    echo "This is expected if you're not on the target system."
    echo ""
fi

echo "Running test.sh with configured arguments..."
echo "Command: $TEST_SCRIPT \"$DEVICE\" \"$SNAPSHOTS_SUBVOLUME\" \"$SUBVOLUME_PAIRS\" \"$PATHS_TO_KEEP\""
echo ""

# Execute the test script with the same arguments as the systemd service
exec "$TEST_SCRIPT" "$DEVICE" "$SNAPSHOTS_SUBVOLUME" "$SUBVOLUME_PAIRS" "$PATHS_TO_KEEP"
