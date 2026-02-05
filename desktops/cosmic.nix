{
  system = { ... }: {
    services.desktopManager.cosmic.enable = true;
    services.displayManager.cosmic-greeter.enable = true;
    services.desktopManager.cosmic.xwayland.enable = true;
  };

  home = { pkgs, theme, ... }: {
    imports = [ ];

    obsidian = {
      enable = true;
      theme = theme.obsidianTheme or "Default";
    };

    ghostty = {
      enable = true;
      theme = theme.ghosttyTheme or theme.name;
    };

    brave = {
      enable = true;
      themeExtensionId = theme.chromeThemeExtensionId;
    };

    alacritty = { enable = true; };

    home.packages = with pkgs; [
      firefox
      vlc
      pavucontrol
      pulsemixer
      tumbler
      ristretto
      popsicle
    ];

    stylix.targets.vscode.enable = false;
  };
}
