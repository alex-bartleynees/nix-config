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
    "/home/${username}/.config/obsidian"

    # Shell and terminal tools
    "/home/${username}/.zsh_history"

    # Cosmic config
    "/home/${username}/.config/cosmic"

    # KDE/Plasma
    "/home/${username}/.config/kwinrc"
    "/home/${username}/.config/kglobalshortcutsrc"
    "/home/${username}/.config/plasmarc"
    "/home/${username}/.config/plasma-workspace"
    "/home/${username}/.config/kde*"
    "/home/${username}/.config/kwinoutputconfig.json"
    "/home/${username}/.local/share/plasma"
    "/home/${username}/.local/share/konsole"
    "/home/${username}/.local/share/konversation"

    # Gaming
    "/home/${username}/.config/OpenRGB"
    "/home/${username}/.config/sunshine"
    "/home/${username}/.local/share/Steam"
    "/home/${username}/.steam"
    "/home/${username}/.steampath"
    "/home/${username}/.steampid"
    "/home/${username}/.config/heroic"
    "/home/${username}/.local/share/heroic"
    "/home/${username}/Games"
  ];
}
