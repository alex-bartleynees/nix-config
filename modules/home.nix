{
  homeConfig = { pkgs, lib, self, username, homeDirectory, theme, desktop, ... }:
    let
      moduleUtils = import "${self}/shared/module-utils.nix" { inherit lib self; };
      desktopImports = if desktop != null then [ (moduleUtils.extractHomeConfig desktop) ] else [ ];
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
    };
}
