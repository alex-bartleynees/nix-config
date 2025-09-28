{ pkgs, lib, ... }: {
  imports =
    [ ../modules/waybar ../modules/rofi ../modules/dunst ../modules/obsidian ../modules/ghostty ../modules/brave ../modules/alacritty ];
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
  ];

  home.pointerCursor = {
    name = lib.mkDefault "Adwaita";
    package = lib.mkDefault pkgs.adwaita-icon-theme;
    size = lib.mkDefault 24;
    x11.enable = true;
  };

  fonts.fontconfig.enable = true;

  stylix.targets.vscode.enable = false;

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
