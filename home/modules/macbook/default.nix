{ pkgs, inputs, ... }: {
  imports = [ ../vscode ../brave ];

  home.packages = with pkgs; [ aerospace tailscale ];

  home.file = {
    ".config/ghostty/config".source = ../ghostty/ghostty-mac.linux;
    ".config/aerospace/aerospace.toml".source = ../aerospace/aerospace.toml;
  };
}
