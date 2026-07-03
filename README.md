# Nix Configuration

A comprehensive Nix flake configuration for managing system configurations across multiple hosts and platforms (NixOS, macOS, WSL).
Highly flexible multi-host and multi-user support.

## 🏗️ Project Structure

```
├── flake.nix             # Main Nix flake configuration
├── hosts.nix             # Host definitions (monitors, profiles, specialisations)
├── desktops/             # Desktop environment configurations (combined NixOS + Home Manager modules)
│   └── common/           # Shared desktop modules (wayland, wlroots, linux-desktop)
├── hardware/             # Disk configs and hardware profiles
├── modules/              # Core system modules and Home Manager application modules
├── profiles/             # System and Home Manager profiles with common module combinations
├── secrets/              # SOPS encrypted secrets
├── lib/                  # Shared configuration helpers (module-utils, mk-system, home-manager, etc.)
├── themes/               # System themes (catppuccin, tokyo-night, gruvbox, nord, everforest)
└── users/                # User-specific configurations
```

### Module Architecture

Every file in `modules/` and `desktops/` uses one of three shapes, which `lib/module-utils.nix` routes automatically:

**NixOS-only** (plain module function — no wrapper):

```nix
{ config, lib, pkgs, ... }: {
  # NixOS system configuration only
}
```

**Home Manager-only** (`homeConfig` wrapper):

```nix
{
  homeConfig = { config, lib, pkgs, ... }: {
    # Home Manager configuration only
  };
}
```

**Combined** (both keys in one file):

```nix
{
  nixosConfig = { config, lib, pkgs, ... }: {
    # NixOS system configuration (services, PAM, etc.)
  };

  homeConfig = { config, lib, pkgs, ... }: {
    # Home Manager configuration (user applications, dotfiles, etc.)
  };
}
```

`lib/module-utils.nix` exports four functions used throughout:

- `importAllNixFiles dir` — scans a directory and returns all NixOS modules (extracts `nixosConfig` from wrappers; skips `homeConfig`-only files)
- `importHomeFiles dir` — scans a directory and returns all Home Manager modules (extracts `homeConfig`; skips everything else)
- `extractSystemConfig desktop` — extracts `nixosConfig` from a named desktop file
- `extractHomeConfig desktop` — extracts `homeConfig` from a named desktop file (returns an empty module if none exists)

## 🖥️ Host Configuration

### hosts.nix

`hosts.nix` centralises all host definitions. Each host is defined declaratively with:

- **desktop**: Default desktop environment
- **monitors**: Per-monitor hardware specs (see below)
- **enableThemeSpecialisations**: Enable runtime theme switching
- **enableDesktopSpecialisations**: Enable desktop environment switching
- **desktopSpecialisations**: Additional desktop environments to build
- **systemProfiles**: System profiles to enable
- **users**: User configurations
- **additionalModules**: Host-specific modules (hardware, WSL, etc.)

### Monitor Schema

Monitor configuration is declared once per host in `hosts.nix` and propagates automatically to every compositor (Hyprland, Sway, Niri, River, Mango, GNOME):

```nix
monitors = [
  {
    name        = "DP-2";                      # connector name
    description = "AOC U27G4 10GR2HA001383";  # used by Hyprland for desc: matching
    vendor      = "AOC";                       # used by GNOME monitors.xml
    product     = "U27G4";
    serial      = "10GR2HA001383";
    width       = 3840;
    height      = 2160;
    refresh     = 160.0;
    x           = 0;                           # logical position
    y           = 0;
    scale       = 1.5;
    vrr         = true;
    transform   = 0;                           # degrees CCW (Wayland convention): 0, 90, 180, 270
    hdr         = false;
    sdrBrightness = 1.0;                       # HDR SDR brightness multiplier
    sdrSaturation = 1.0;                       # HDR SDR saturation multiplier
    primary     = true;
  }
];
```

Adding or renaming a monitor only requires editing `hosts.nix` — all compositor configs, workspace assignments, idle/dpms commands, and GNOME monitor XML are derived from this single source.

### Available Hosts

| Host       | Platform  | Desktop  | Description                                                                  |
| ---------- | --------- | -------- | ---------------------------------------------------------------------------- |
| `desktop`  | NixOS     | Hyprland | Main desktop with theme and DE specialisations (Sway, Niri, River, and more) |
| `macbook`  | macOS     | -        | MacBook configuration with nix-darwin                                        |
| `media`    | NixOS     | Hyprland | Media server with Samba, backup services, and HDR display                    |
| `thinkpad` | NixOS     | Niri     | ThinkPad laptop with TLP power management and theme specialisations          |
| `wsl`      | NixOS-WSL | None     | Windows Subsystem for Linux setup                                            |

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
darwin-rebuild switch --flake .#macbook
```

### Home Manager

```bash
home-manager switch --flake .
```

## 🔧 Common Commands

```bash
# Update all flake inputs
nix flake update

# Update specific input
nix flake update nixpkgs

# Check flake for errors
nix flake check

# Build from GitHub repository
sudo nixos-rebuild switch --flake github:alex-bartleynees/nix-config#desktop
```

### Specialisations

The desktop host includes multiple desktop environment and theme specialisations:

```bash
# Switch desktop environment
sudo nixos-rebuild switch --flake .#desktop --specialisation sway
sudo nixos-rebuild switch --flake .#desktop --specialisation niri
sudo nixos-rebuild switch --flake .#desktop --specialisation river
sudo nixos-rebuild switch --flake .#desktop --specialisation gnome
sudo nixos-rebuild switch --flake .#desktop --specialisation kde
sudo nixos-rebuild switch --flake .#desktop --specialisation cosmic
```

## 🎨 Features

### Core Modules

- **Gaming**: Steam, Sunshine and Moonlight game streaming
- **NVIDIA**: Proprietary drivers with CUDA support and PRIME offloading
- **Docker**: Container runtime with user access
- **Tailscale**: Mesh VPN networking
- **OpenRGB**: RGB lighting control with optional boot-time RGB disable (`turnOffOnBoot`)
- **Stylix**: System-wide theming
- **Impermanence**: BTRFS-based filesystem reset with selective persistence

### Modules (`modules/`)

All files in `modules/` are auto-imported. The module type is detected by shape:

- **NixOS modules** (plain function): `backup`, `docker`, `gaming`, `impermanence`, `nvidia`, `openrgb`, `tailscale`, `voyager`, etc.
- **Home Manager modules** (`{ homeConfig = ...; }`): `git`, `shell`, `waybar`, `udiskie`, `awww`, `vicinae`, `ghostty`, `neovim`, `vscode`, etc.
- **Combined modules** (`{ nixosConfig = ...; homeConfig = ...; }`): `swayidle`, `hypridle` — handles PAM at the NixOS level and idle/lock at the home level in a single file.

Notable desktop-related home modules that are compositor-agnostic and bind to a session target:

- **swayidle**: Idle management and screen locking; the combined module also sets `security.pam.services.swaylock` system-wide
- **waybar**: Status bar with an optional systemd user service bound to a compositor session target
- **udiskie**: Automount daemon as a systemd user service
- **awww**: Wallpaper daemon with optional wallpaper on start
- **vicinae**: App launcher as a systemd user service

Usage pattern in desktop files:

```nix
swayidle = {
  enable = true;
  wallpaper = background;
  displayOffCommand = ''swaymsg "output * dpms off"'';
  displayOnCommand  = ''swaymsg "output * dpms on"'';
};

waybar.sessionTarget = "sway-session.target";
udiskie  = { enable = true; sessionTarget = "sway-session.target"; };
awww     = { enable = true; sessionTarget = "sway-session.target"; wallpaper = background; };
vicinae  = { enable = true; sessionTarget = "sway-session.target"; };
```

### System Profiles

- **base**: Core services for all machines (Tailscale, Docker)
- **linux-desktop**: Desktop system with theming, impermanence, and common desktop services
- **gaming-workstation**: High-performance desktop with gaming, NVIDIA GPU, and RGB lighting
- **media-server**: Media server with hardware acceleration and network routing
- **linux-laptop**: Laptop power management with TLP

Profile inheritance:

- `gaming-workstation` → `linux-desktop` → `base`
- `media-server` → `linux-desktop` → `base`
- `linux-laptop` → `linux-desktop` → `base`

### Desktop Environments

- **Hyprland**: Dynamic tiling compositor (primary on desktop and media)
- **Sway**: Tiling Wayland compositor
- **Niri**: Scrollable-tiling Wayland compositor (primary on thinkpad)
- **River**: Efficient tiling window manager
- **Mango** (`mangowc`): Wayland compositor with scroller and master-stack layouts
- **GNOME**: Full GNOME desktop with extensions
- **KDE Plasma**: Complete KDE experience
- **Cosmic**: System76's Rust-based desktop environment

### Applications

- Development: VSCode, JetBrains Rider, Neovim
- Terminal: Ghostty, Tmux
- Browser: Brave with declarative extensions and themes
- Media: Various media players and codecs

### User Home Profiles

Modular home profiles allow users to compose their environment:

- **developer**: Git, Zsh + Oh My Zsh + Powerlevel10k, Neovim, tmux, ripgrep, fzf, lazygit, direnv, zoxide, Atuin
- **vscode-developer**: VSCode with extensions
- **rider-developer**: JetBrains Rider
- **backend-developer**: Backend development tools
- **reader**: E-reader and document tools
- **work**: Microsoft Teams and work-specific applications
- **host-\***: Host-specific overrides (kanshi display profiles, etc.)

## 🔄 Impermanence

BTRFS-based filesystem reset with selective persistence:

```nix
impermanence = {
  enable = true;
  persistPaths = [
    "/etc/sops"
    "/etc/ssh"
    "/var/log"
    "/var/lib/nixos"
  ];
  resetSubvolumes = [ "@home" "@var" ];
  subvolumes = {
    "@home" = { mountpoint = "/home"; };
    "@var"  = { mountpoint = "/var"; };
  };
};
```

## 💾 Disk Encryption

[disko](https://github.com/nix-community/disko) declarative disk partitioning with LUKS encryption. Desktop and ThinkPad use full disk encryption with BTRFS subvolumes, compressed with zstd. The media server uses unencrypted disks for simplicity.

## 🔐 Secrets Management

[SOPS](https://github.com/Mic92/sops-nix) for encrypted secrets stored in `secrets/secrets.yaml`.

## 📦 Key Dependencies

- **nixpkgs**: Main package repository (nixos-unstable)
- **home-manager**: User environment management
- **nix-darwin**: macOS system management
- **nixos-wsl**: WSL integration
- **stylix**: System-wide theming
- **sops-nix**: Secret management
- **disko**: Declarative disk partitioning
- **nixos-hardware**: Hardware-specific configurations
- **niri-flake**: Niri compositor and packages
