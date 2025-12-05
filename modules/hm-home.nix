{ pkgs, lib, username, homeDirectory, hostName, theme, desktop, ... }:
let
  hostImports = if builtins.pathExists ../machines/hm-${hostName}.nix then
    [ ../machines/hm-${hostName}.nix ]
  else
    [ ];
  desktopImports =
    if desktop != null && builtins.pathExists ../desktops/hm-${desktop}.nix then
      [ ../desktops/hm-${desktop}.nix ]
    else
      [ ];

  allImports = hostImports ++ desktopImports;
in {
  imports = allImports;
  home.username = lib.mkDefault username;
  home.homeDirectory = lib.mkDefault homeDirectory;
  home.stateVersion = "24.11";

  programs.home-manager.enable = true;

  programs.zsh.enable = true;

  home.packages = with pkgs; [
    font-awesome
    icomoon-feather
    iosevka
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    nerd-fonts.hack
  ];

  home.sessionVariables = { BACKGROUND = theme.wallpaper; };

}
