{
  homeConfig = { pkgs, lib, self, username, homeDirectory, osConfig, ... }:
    let
      theme = osConfig.myConfig.theme;
      desktop = osConfig.myConfig.desktop;
      paths = import "${self}/paths.nix" self;
      moduleUtils =
        import "${paths.lib}/module-utils.nix" { inherit lib self; };
      desktopImports = if desktop != "none" then
        [ (moduleUtils.extractHomeConfig desktop) ]
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
    };
}
