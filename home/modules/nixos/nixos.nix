{ pkgs, inputs, background, hostName, theme, ... }: {
  imports = [ ../vscode ../waybar ../sway ../rofi ../dunst ../rider ];
  home.packages = with pkgs; [
    qbittorrent-enhanced
    firefox
    grim
    slurp
    feh
    unstable.ghostty
    (symlinkJoin {
      name = "code-cursor";
      paths = [ code-cursor ];
      buildInputs = [ makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/cursor \
          --add-flags "--disable-gpu"
      '';
    })
  ];

  programs.brave = {
    enable = true;
    package = (pkgs.brave.override { commandLineArgs = [ "--disable-gpu" ]; });
  };

  home.pointerCursor = {
    name = "Adwaita";
    package = pkgs.adwaita-icon-theme;
    size = 24;
  };

  home.file = { ".config/ghostty/config".source = ../ghostty/ghostty.linux; };

  fonts.fontconfig.enable = true;
}
