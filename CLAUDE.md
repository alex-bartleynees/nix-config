# Claude Code Configuration

This is a Nix configuration repository for managing system configurations across multiple hosts.

## Project Structure

- `flake.nix` - Main Nix flake configuration
- `core/` - Core system modules (gaming, nvidia, openrgb)
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

## Recent Refactoring Changes

The configuration has been refactored to improve modularity and organization:

- **New `core/` directory**: Extracted common system modules (gaming, nvidia, openrgb) from host-specific configurations
- **Simplified host configurations**: Moved shared functionality to core modules, reducing duplication
- **Modular design**: Core modules can be imported by different hosts as needed

## Development

This configuration uses Nix flakes for reproducible system management across different environments.