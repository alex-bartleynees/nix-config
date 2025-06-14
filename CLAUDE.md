# Claude Code Configuration

This is a Nix configuration repository for managing system configurations across multiple hosts.

## Project Structure

- `flake.nix` - Main Nix flake configuration
- `home/` - Home Manager configurations
- `hosts/` - Host-specific configurations (desktop, macbook, wsl)
- `shared/` - Shared configurations across hosts
- `users/` - User-specific configurations

## Hosts

- **desktop** - Main desktop configuration with multiple DE specializations (GNOME, KDE, Cosmic)
- **macbook** - macOS configuration
- **wsl** - Windows Subsystem for Linux configuration

## Common Commands

```bash
# Rebuild system configuration
sudo nixos-rebuild switch --flake .

# Rebuild home manager configuration
home-manager switch --flake .

# Update flake inputs
nix flake update

# Check flake
nix flake check
```

## Development

This configuration uses Nix flakes for reproducible system management across different environments.