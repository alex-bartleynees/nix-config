# homeModule: true
{ pkgs, lib, username, homeDirectory, theme, desktop, ... }:
let
  # Module extractors
  extractors = import ../shared/module-extractors.nix;

  # Extract homeConfig from combined desktop module if it exists
  desktopImports = if desktop != null
  && builtins.pathExists (../desktops + "/${desktop}.nix") then
    [ (extractors.extractHomeConfig desktop) ]
  else
    [ ];
in {
  imports = desktopImports;
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
