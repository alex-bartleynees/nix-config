{ pkgs, ... }: {
  imports = [ ../../modules/vscode ../../modules/brave ];

  home.packages = with pkgs; [ aerospace tailscale ];

  home.file = {
    ".config/ghostty/config".source = ../../modules/ghostty/ghostty-mac.linux;
    ".config/aerospace/aerospace.toml".source =
      ../../modules/aerospace/aerospace.toml;
  };
}
