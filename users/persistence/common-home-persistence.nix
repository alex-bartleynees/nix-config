{ username, ... }: {
  commonHomePersistPaths = [
    # User SSH keys
    "/home/${username}/.ssh"
    "/home/${username}/.local/share/keyrings"

    # Browsers (profiles, bookmarks, extensions, passwords)
    "/home/${username}/.config/BraveSoftware" # Brave browser data
    "/home/${username}/.mozilla" # Firefox profiles and data

    # Applications with important user data
    "/home/${username}/Documents" # User documents
    "/home/${username}/.config/obsidian" # Obsidian vaults and settings

    # Shell and terminal tools
    "/home/${username}/.zsh_history"

    # Gaming
    "/home/${username}/.config/OpenRGB"
    "/home/${username}/.config/sunshine"
    "/home/${username}/.local/share/Steam"
    "/home/${username}/.steam"
    "/home/${username}/.steampath"
    "/home/${username}/.steampid"
  ];
}
