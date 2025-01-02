
{ pkgs, inputs, ... }: {

  home.packages = with pkgs; [
    unstable.aerospace
    unstable.tailscale
  ]; 

  home.file = {
    ".config/ghostty/config".source = ../ghostty/ghostty-mac.linux;
    ".config/aerospace/aerospace.toml".source = ../aerospace/aerospace.toml;
  };
}
