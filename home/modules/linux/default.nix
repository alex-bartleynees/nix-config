{ pkgs, inputs, hostName, theme, lib, ... }: {
  imports = [ ../waybar ../rofi ../dunst ../obsidian ../ghostty ];
  home.packages = with pkgs; [ firefox vlc xfce.thunar pavucontrol pulsemixer ];

  programs.brave = { enable = true; };

  home.pointerCursor = {
    name = lib.mkDefault "Adwaita";
    package = lib.mkDefault pkgs.adwaita-icon-theme;
    size = lib.mkDefault 24;
    x11.enable = true;
  };

  fonts.fontconfig.enable = true;

  stylix.targets.vscode.enable = false;
}
