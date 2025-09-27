# Nix Configuration

A comprehensive Nix flake configuration for managing system configurations across multiple hosts and platforms (NixOS, macOS, WSL).
Currently a single user configuration.

## 🏗️ Project Structure

```
├── flake.nix             # Main Nix flake configuration
├── hosts.nix             # Host definitions and configurations
├── core/                 # Core system modules
│   ├── desktops/         # Desktop environment configurations
│   ├── modules/          # System modules (gaming, nvidia, docker, etc.). Imported for all systems and can be enabled/disabled
│   └── themes/           # System themes (catppuccin, tokyo-night, nord, everforest) switchable at runtime
├── home/                 # Home Manager configurations
│   └── hosts/            # Host specific application configurations
│   └── desktops/         # Desktop specific application configurations
│   └── modules/          # User application configurations
├── hosts/                # Host-specific configurations
│   ├── desktop/          # Main desktop with DE specializations
│   ├── macbook/          # macOS configuration
│   ├── media/            # Media server configuration
│   ├── thinkpad/         # ThinkPad laptop configuration
│   └── wsl/              # Windows Subsystem for Linux
├── secrets/              # SOPS encrypted secrets
├── shared/               # Shared configurations helpers across hosts
└── users/                # User-specific configurations
```

## 🖥️ Host Configuration

### hosts.nix

The `hosts.nix` file centralizes host definitions and their configurations. Each host is defined with:

- **hostPath**: Path to the host-specific configuration directory
- **desktop**: Default desktop environment for the host
- **enableThemeSpecialisations**: Whether to enable theme switching specializations
- **enableDesktopSpecialisations**: Whether to enable desktop environment specializations
- **desktopSpecialisations**: List of additional desktop environments to include
- **additionalModules**: Host-specific Nix modules (e.g., hardware modules, WSL)

### Available Hosts

| Host       | Platform  | Desktop   | Description                                                              |
| ---------- | --------- | --------- | ------------------------------------------------------------------------ |
| `desktop`  | NixOS     | Hyprland  | Main desktop with theme and DE specializations (Sway, River)            |
| `macbook`  | macOS     | -         | MacBook configuration with nix-darwin                                    |
| `media`    | NixOS     | GNOME     | Media server with Samba and backup services                             |
| `thinkpad` | NixOS     | River     | ThinkPad laptop with TLP power management and theme specializations     |
| `wsl`      | NixOS-WSL | None      | Windows Subsystem for Linux setup                                       |

## 🚀 Quick Start

### NixOS Systems

```bash
# Build and switch to desktop configuration
sudo nixos-rebuild switch --flake .#desktop

# Build and switch to other hosts
sudo nixos-rebuild switch --flake .#media
sudo nixos-rebuild switch --flake .#thinkpad
sudo nixos-rebuild switch --flake .#wsl
```

### macOS Systems

```bash
# Build and switch to macbook configuration
darwin-rebuild switch --flake .#macbook
```

### Home Manager

```bash
# Switch home manager configuration
home-manager switch --flake .
```

## 🔧 Common Commands

### System Management

```bash
# Update all flake inputs
nix flake update

# Update specific input
nix flake update nixpkgs

# Check flake for errors
nix flake check

# Show flake outputs
nix flake show

# Enter development shell
nix develop
```

### Build from Remote

```bash
# Build from GitHub repository
sudo nixos-rebuild switch --flake github:alex-bartleynees/nix-config#desktop
```

### Specializations (Desktop Only)

The desktop host includes multiple desktop environment specializations:

```bash
# Boot into GNOME
sudo nixos-rebuild switch --flake .#desktop --specialisation gnome

# Boot into KDE
sudo nixos-rebuild switch --flake .#desktop --specialisation kde

# Boot into Cosmic
sudo nixos-rebuild switch --flake .#desktop --specialisation cosmic

# Boot into Sway
sudo nixos-rebuild switch --flake .#desktop --specialisation sway
```

## 🎨 Features

### Core Modules

- **Gaming**: Steam, Sunshine and Moonlight game streaming
- **NVIDIA**: Proprietary drivers with CUDA support
- **Docker**: Container runtime with user access
- **Tailscale**: Mesh VPN networking
- **OpenRGB**: RGB lighting control
- **Stylix**: System-wide theming
- **Impermanence**: Custom BTRFS-based filesystem reset with selective persistence

### Desktop Environments

- **GNOME**: Full GNOME desktop with extensions
- **KDE Plasma**: Complete KDE experience
- **Cosmic**: System76's new desktop environment
- **Sway**: Tiling Wayland compositor
- **Hyprland**: Dynamic tiling compositor
- **River**: Extremely efficient tiling window manager, great on laptops.

### Applications

- Development: VSCode, JetBrains Rider, Neovim
- Terminal: Alacritty, Ghostty, Tmux
- Browser: Brave with declarative extensions and themes
- Media: Various media players and codecs

## 🔄 Impermanence

This configuration includes a custom impermanence module that provides BTRFS-based filesystem reset capabilities with selective persistence. The module automatically resets specified subvolumes on boot while preserving critical data.

### Features

- **Automatic Reset**: Resets configured BTRFS subvolumes on every boot
- **Selective Persistence**: Preserves specified paths (SSH keys, logs, system state)
- **Flexible Configuration**: Choose which subvolumes to reset or reset all except protected ones
- **Snapshot Management**: Uses BTRFS snapshots for efficient file operations
- **Safety Protections**: Never resets critical subvolumes (@nix, @snapshots)

### Configuration

```nix
impermanence = {
  enable = true;
  persistPaths = [
    "/etc/sops"
    "/etc/ssh"
    "/var/log"
    "/var/lib/nixos"
  ];
  resetSubvolumes = [ "@home" "@var" ]; # Empty list resets all non-protected
  subvolumes = {
    "@home" = { mountpoint = "/home"; };
    "@var" = { mountpoint = "/var"; };
  };
};
```

## 💾 Disk Encryption with Disko

This configuration uses [disko](https://github.com/nix-community/disko) for declarative disk partitioning with LUKS encryption support.

### LUKS Encryption Setup

Several hosts (desktop, thinkpad) use full disk encryption with LUKS:

```nix
# Example LUKS configuration
content = {
  type = "luks";
  name = "crypted";
  settings = { allowDiscards = true; };
  content = {
    type = "btrfs";
    extraArgs = [ "-f" "-L" "nixos" ];
    subvolumes = {
      "@" = {
        mountpoint = "/";
        mountOptions = [ "compress=zstd" "noatime" ];
      };
      # Additional subvolumes...
    };
  };
};
```

### Key Features

- **Full disk encryption**: Root and swap partitions encrypted with LUKS
- **TRIM support**: `allowDiscards = true` enables TRIM for SSDs
- **Hibernate support**: Encrypted swap with `resumeDevice = true`
- **Btrfs subvolumes**: Encrypted btrfs with compression and snapshots

### Implementation Examples

- **Desktop** (`hosts/desktop/modules/disk-config.nix`): NVMe with encrypted root and swap
- **ThinkPad** (`hosts/thinkpad/modules/disk-config.nix`): Laptop-optimized
- **Media Server** (`hosts/media/modules/disk-config.nix`): Unencrypted for simplicity

### Setting Up New Encrypted Host

1. Copy an existing encrypted disk config (e.g., from desktop or thinkpad)
2. Adjust device paths (`/dev/nvme0n1`, `/dev/sda`, etc.)
3. Modify partition sizes as needed
4. Ensure boot partition is unencrypted (type: "filesystem", format: "vfat")
5. Set unique LUKS container names (`name = "crypted"`)

### Boot Process

With LUKS encryption, the boot process requires:

1. UEFI loads the unencrypted boot partition
2. GRUB prompts for disk encryption password
3. System unlocks encrypted partitions and continues boot

## 🔐 Secrets Management

This configuration uses [SOPS](https://github.com/Mic92/sops-nix) for secret management. Secrets are encrypted and stored in `secrets/secrets.yaml`.

## 📦 Key Dependencies

- **nixpkgs**: Main package repository (nixos-unstable)
- **home-manager**: User environment management
- **nix-darwin**: macOS system management
- **nixos-wsl**: WSL integration
- **stylix**: System theming
- **sops-nix**: Secret management
- **disko**: Disk partitioning
- **nixos-hardware**: Hardware-specific configurations

## 📝 Development

This configuration uses Nix flakes for reproducible system management. Each host can enable relevant core modules as needed, making the configuration highly modular and maintainable.
