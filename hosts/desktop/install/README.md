# NixOS Installation with LUKS Encryption

This directory contains the configuration files for installing NixOS with LUKS full-disk encryption using disko.

## Files

- `disko-config.nix` - Disk partitioning and LUKS encryption configuration
- `install-flake.nix` - Installation-time flake with SSH access and installation script

## Quick Start

### Automated Installation (Recommended)

1. Boot from NixOS ISO
2. Clone your configuration and navigate to install directory
3. Run the automated install script:

```bash
nix run .#install-script
```

The script will handle disk partitioning, LUKS encryption, and provide clear next steps.

### Manual Steps After Script

After the install script completes, follow the displayed instructions:

1. **Copy configuration:**
   ```bash
   sudo cp -r /path/to/nix-config /mnt/etc/nixos/
   ```

2. **Add LUKS configuration to hardware-configuration.nix:**
   ```bash
   sudo nano /mnt/etc/nixos/hardware-configuration.nix
   ```
   Add this to the configuration:
   ```nix
   boot.initrd.luks.devices."crypted" = {
     device = "/dev/nvme1n1p3";
     preLVM = true;
   };
   ```

3. **Install NixOS:**
   ```bash
   sudo nixos-install --flake /mnt/etc/nixos/nix-config#desktop
   ```

4. **Set root password and reboot:**
   ```bash
   sudo nixos-enter --root /mnt -c 'passwd'
   reboot
   ```

## Disk Layout

The configuration creates this layout on `/dev/nvme1n1`:

```
/dev/nvme1n1
├── /dev/nvme1n1p1  512M   EFI System Partition (FAT32)  -> /boot
├── /dev/nvme1n1p2   32G   Linux swap
└── /dev/nvme1n1p3  1.8T   LUKS encrypted partition
    └── /dev/mapper/crypted  XFS filesystem              -> /
```

## Remote Installation

The install flake includes SSH configuration for remote installation:

### SSH Access
- Root login enabled (key-based authentication only)
- Your SSH public key is pre-authorized
- Connect after booting installer: `ssh root@<installer-ip>`

### Remote Installation Process
1. Boot target machine from NixOS ISO
2. SSH in from another machine
3. Clone configuration and run install script remotely

## Manual Installation Steps

If you prefer manual control over the automated script:

### 1. Prepare LUKS Key (Optional)
```bash
echo "your-encryption-password" > /tmp/secret.key
chmod 600 /tmp/secret.key
```

### 2. Run Disko
```bash
sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- --mode disko ./disko-config.nix
```

### 3. Generate Hardware Config
```bash
sudo nixos-generate-config --root /mnt
```

### 4. Continue with manual steps above...

## Important Notes

### LUKS Password
- **Critical:** Remember your encryption password - data is unrecoverable if lost
- You'll enter the password at every boot
- Consider using a password manager or secure backup

### Key File Behavior
- `/tmp/secret.key` is temporary and cleared on reboot
- Configuration has `fallbackToPassword = true` for interactive entry
- Key file is only used during installation, not for the final system

### Security
- Root partition is fully encrypted with LUKS
- Boot partition is **not encrypted** (required for UEFI)
- Swap partition is not encrypted in this configuration

## Troubleshooting

### Boot Issues
- Ensure LUKS configuration is in `hardware-configuration.nix`
- Verify device path is `/dev/nvme1n1p3`
- Check that `preLVM = true` is set

### Password Problems
- Installer will retry if password is incorrect
- Ensure Caps Lock is off
- Password is case-sensitive

### Recovery Access
To access encrypted system from rescue environment:
```bash
sudo cryptsetup luksOpen /dev/nvme1n1p3 crypted
sudo mount /dev/mapper/crypted /mnt
sudo mount /dev/nvme1n1p1 /mnt/boot
sudo nixos-enter --root /mnt
```

### Install Script Issues
- Ensure you're in the install directory when running the script
- Check network connectivity for downloading packages
- Verify the flake syntax with: `nix flake check`

## What's Next

After successful installation:
1. Boot into your new encrypted NixOS system
2. Enter LUKS password at boot prompt
3. Log in with your configured user account
4. Your system is ready with full disk encryption!