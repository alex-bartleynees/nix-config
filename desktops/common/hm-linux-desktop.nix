{ pkgs, lib, desktop, theme, ... }: {
  imports = [ ];

  waybar = {
    enable = true;
    desktop = desktop;
  };

  rofi = { enable = true; };

  obsidian = {
    enable = true;
    theme = theme.obsidianTheme or "Default";
  };

  ghostty = {
    enable = true;
    theme = theme.ghosttyTheme or theme.name;
  };

  dunst = {
    enable = true;
    colors = {
      background = theme.themeColors.groupbar_inactive;
      foreground = theme.themeColors.text;
      frameColor = theme.themeColors.active_border;
      criticalFrameColor = theme.themeColors.locked_active;
    };
  };

  brave = {
    enable = true;
    themeExtensionId = theme.chromeThemeExtensionId;
  };

  alacritty = { enable = true; };

  home.packages = with pkgs; [
    firefox
    vlc
    xfce.thunar
    pavucontrol
    pulsemixer
    xfce.tumbler
    xfce.ristretto
    wdisplays
    popsicle

    # Wallpaper and background management
    swww

    # Screenshot and clipboard utilities
    grim
    slurp
    wl-clipboard
    wl-clipboard-x11

    # Application launcher
    rofi
  ];

  home.pointerCursor = {
    name = lib.mkDefault "Adwaita";
    package = lib.mkDefault pkgs.adwaita-icon-theme;
    size = lib.mkDefault 24;
    x11.enable = true;
  };

  fonts.fontconfig.enable = true;

  stylix.targets.vscode.enable = false;
  stylix.targets.waybar.enable = false;

  services.gnome-keyring = {
    enable = true;
    components = [ "secrets" ];
  };

  systemd.user.services.polkit-gnome-authentication-agent-1 = {
    Unit = {
      Description = "polkit-gnome-authentication-agent-1";
      Wants = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Install = { WantedBy = [ "graphical-session.target" ]; };
    Service = {
      Type = "simple";
      ExecStart =
        "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
  };
}
