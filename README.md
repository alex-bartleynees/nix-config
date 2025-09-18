# Nix Configuration

A comprehensive Nix flake configuration for managing system configurations across multiple hosts and platforms (NixOS, macOS, WSL).
Currently a single user configuration.

## 🏗️ Project Structure

```
├── flake.nix             # Main Nix flake configuration
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

## 🖥️ Hosts

| Host       | Platform  | Description                                                    |
| ---------- | --------- | -------------------------------------------------------------- |
| `desktop`  | NixOS     | Main desktop with Hyprland, GNOME, KDE, Cosmic, and Sway specializations |
| `macbook`  | macOS     | MacBook configuration with nix-darwin                          |
| `media`    | NixOS     | Media server with Samba and backup services                    |
| `thinkpad` | NixOS     | ThinkPad laptop with TLP power management                      |
| `wsl`      | NixOS-WSL | Windows Subsystem for Linux setup                              |

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
- **River*: Extremely efficient tiling window manager, great on laptops.

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

This configuration uses Nix flakes for reproducible system management. Each host can import relevant core modules as needed, making the configuration highly modular and maintainable.
