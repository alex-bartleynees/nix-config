{ pkgs, inputs, ... }: {
  imports = [ ../vscode ../brave ../rider ../obsidian ];

  home.packages = with pkgs; [
    qbittorrent-enhanced
    firefox
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

  programs.brave = { enable = true; };

  home.file = {
    ".config/ghostty/config".source = ../ghostty/ghostty-mac.linux;
  };

  fonts.fontconfig.enable = true;
}

