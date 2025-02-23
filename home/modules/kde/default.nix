{ pkgs, inputs, ... }: {
  imports = [ ../vscode ../brave ../rider ../obsidian ];

  home.packages = with pkgs; [
    qbittorrent-enhanced
    firefox
    unstable.ghostty
    code-cursor
  ];

  programs.brave = { enable = true; };

  home.file = {
    ".config/ghostty/config".source = ../ghostty/ghostty-mac.linux;
  };

  fonts.fontconfig.enable = true;
}

