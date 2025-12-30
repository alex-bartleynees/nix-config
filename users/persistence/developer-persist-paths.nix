{ username, ... }: {
  commonPersistPaths = [
    # Development tools
    "/home/${username}/.config/JetBrains" # Rider settings and projects
    "/home/${username}/.local/share/JetBrains"
    "/home/${username}/.dotnet" # .NET user secrets and tools
    "/home/${username}/.nuget" # NuGet package cache
    "/home/${username}/.claude"
    "/home/${username}/.claude.json"

    # Applications with important user data
    "/home/${username}/workspaces"
    "/home/${username}/.config/Code" # VSCode authentication, settings, and workspaces
    "/home/${username}/.vscode/argv.json" # VSCode command line arguments
    "/home/${username}/.vscode-server" # Remote SSH sessions
    "/home/${username}/azuredatastudio"
    "/home/${username}/.config/yaak" # Yaak API client settings and collections
    "/home/${username}/.local/share/yaak" # Yaak API client data

    # Config files
    "/home/${username}/.config/nix-config"
    "/home/${username}/.config/nix-devenv"
    "/home/${username}/.config/nixos-secrets"
    "/home/${username}/.config/dotfiles"
    "/home/${username}/.config/sops"

    # Shell and terminal tools
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

  ];
}
