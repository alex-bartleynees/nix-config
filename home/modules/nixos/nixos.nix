{ pkgs, inputs, background, hostName, theme, lib, ... }: {
  imports = [
    ../vscode
    ../waybar
    ../sway
    ../hyprland
    ../rofi
    ../dunst
    ../rider
    ../obsidian
  ];
  home.packages = with pkgs; [
    qbittorrent-enhanced
    firefox
    grim
    slurp
    feh
    ghostty
    zed-editor
    vlc
    nautilus
    # (symlinkJoin {
    #   name = "code-cursor";
    #   paths = [ code-cursor ];
    #   buildInputs = [ makeWrapper ];
    #   postBuild = ''
    #     wrapProgram $out/bin/cursor \
    #       --add-flags "--disable-gpu"
    #   '';
    # })
  ];

  programs.brave = {
    enable = true;
    package = (pkgs.brave.override { commandLineArgs = [ "--disable-gpu" ]; });
  };

  home.pointerCursor = {
    name = lib.mkDefault "Adwaita";
    package = lib.mkDefault pkgs.adwaita-icon-theme;
    size = lib.mkDefault 24;
    x11.enable = true;
  };

  home.file = { ".config/ghostty/config".source = ../ghostty/ghostty.linux; };

  fonts.fontconfig.enable = true;
}
