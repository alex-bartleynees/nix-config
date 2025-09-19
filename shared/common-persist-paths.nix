{ ... }: {
  commonPersistPaths = [
    # System critical paths
    "/etc/sops"
    "/etc/ssh" # SSH host keys
    "/etc/machine-id" # Unique machine identifier
    "/var/log" # System logs
    "/var/lib/nixos" # NixOS state
    "/var/lib/systemd/random-seed" # Random seed for reproducibility
    "/var/lib/systemd/coredump" # Core dumps for debugging
    "/var/lib/systemd/timers" # Systemd timer state
    "/var/lib/tailscale" # Tailscale state
    "/var/lib/bluetooth" # Bluetooth pairings and device info
    "/var/lib/colord" # Color management profiles
    "/var/lib/docker" # Docker images, containers, volumes, networks
    "/etc/NetworkManager/system-connections" # Wifi passwords and network configs

    # User SSH keys
    "/home/alexbn/.ssh"
    "/home/alexbn/.local/share/keyrings"

    # Development tools
    "/home/alexbn/.config/JetBrains" # Rider settings and projects
    "/home/alexbn/.local/share/JetBrains"
    "/home/alexbn/.dotnet" # .NET user secrets and tools
    "/home/alexbn/.nuget" # NuGet package cache
    "/home/alexbn/.claude"
    "/home/alexbn/.claude.json"

    # Browsers (profiles, bookmarks, extensions, passwords)
    "/home/alexbn/.config/BraveSoftware" # Brave browser data
    "/home/alexbn/.mozilla" # Firefox profiles and data

    # Applications with important user data
    "/home/alexbn/.config/obsidian" # Obsidian vaults and settings
    "/home/alexbn/Documents" # User documents
    "/home/alexbn/workspaces"
    "/home/alexbn/.config/teams-for-linux"
    "/home/alexbn/.vscode"
    "/home/alexbn/.config/vscode"
    "/home/alexbn/.local/share/vscode"

    # Config files
    "/home/alexbn/.config/nix-config"
    "/home/alexbn/.config/nix-devenv"
    "/home/alexbn/.config/nixos-secrets"
    "/home/alexbn/.config/dotfiles"
    "/home/alexbn/.config/sops"

    # Shell and terminal tools
    "/home/alexbn/.zsh_history"
    "/home/alexbn/.p10k.zsh" # Powerlevel10k configuration
    "/home/alexbn/.local/share/atuin" # Atuin shell history database
    "/home/alexbn/.local/share/zoxide" # Zoxide frecency database
    "/home/alexbn/.config/tmuxinator" # Tmuxinator project configs
    "/home/alexbn/.local/share/nvim" # Neovim plugins and data
    "/home/alexbn/.cache/nvim" # Neovim cache
    "/home/alexbn/.local/share/direnv"
    "/home/alexbn/.local/state/lazygit"
  ];
}
