{ username, ... }: {
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
    "/home/${username}/.ssh"
    "/home/${username}/.local/share/keyrings"

    # Development tools
    "/home/${username}/.config/JetBrains" # Rider settings and projects
    "/home/${username}/.local/share/JetBrains"
    "/home/${username}/.dotnet" # .NET user secrets and tools
    "/home/${username}/.nuget" # NuGet package cache
    "/home/${username}/.claude"
    "/home/${username}/.claude.json"

    # Browsers (profiles, bookmarks, extensions, passwords)
    "/home/${username}/.config/BraveSoftware" # Brave browser data
    "/home/${username}/.mozilla" # Firefox profiles and data

    # Applications with important user data
    "/home/${username}/.config/obsidian" # Obsidian vaults and settings
    "/home/${username}/Documents" # User documents
    "/home/${username}/workspaces"
    "/home/${username}/.config/teams-for-linux"
    "/home/${username}/.config/Code" # VSCode authentication, settings, and workspaces
    "/home/${username}/.vscode/argv.json" # VSCode command line arguments
    "/home/${username}/.vscode-server" # Remote SSH sessions

    # Config files
    "/home/${username}/.config/nix-config"
    "/home/${username}/.config/nix-devenv"
    "/home/${username}/.config/nixos-secrets"
    "/home/${username}/.config/dotfiles"
    "/home/${username}/.config/sops"

    # Shell and terminal tools
    "/home/${username}/.zsh_history"
    "/home/${username}/.p10k.zsh" # Powerlevel10k configuration
    "/home/${username}/.local/share/atuin" # Atuin shell history database
    "/home/${username}/.local/share/zoxide" # Zoxide frecency database
    "/home/${username}/.config/tmuxinator" # Tmuxinator project configs
    "/home/${username}/.local/share/nvim" # Neovim plugins and data
    "/home/${username}/.cache/nvim" # Neovim cache
    "/home/${username}/.local/state/nvim" # Neovim state
    "/home/${username}/.local/share/direnv"
    "/home/${username}/.local/state/lazygit"
    "/home/${username}/.config/github-copilot"

    "/home/${username}/.config/OpenRGB"

    # Gaming
    "/home/${username}/.config/sunshine"
    "/home/${username}/.local/share/Steam"
    "/home/${username}/.steam"
    "/home/${username}/.steampath"
    "/home/${username}/.steampid"
  ];
}
