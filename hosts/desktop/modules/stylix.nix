{ lib, config, pkgs, background, ... }: {
  stylix.enable = true;
  stylix.enableReleaseChecks = false;
  stylix.image = background.wallpaper;
  stylix.polarity = "dark";
  stylix.base16Scheme =
    "${pkgs.base16-schemes}/share/themes/tokyo-night-dark.yaml";
  stylix.opacity = {
    desktop = 0.5;
    terminal = 0.9;
  };
  stylix.cursor = {
    package = pkgs.adwaita-icon-theme;
    name = "Adwaita";
    size = 24;
  };

  stylix.fonts.sizes = {
    applications = 12;
    terminal = 12;
    desktop = 8;
    popups = 8;
  };

  stylix.fonts = {
    monospace = {
      package = pkgs.nerd-fonts.jetbrains-mono;
      name = "JetBrainsMono Nerd Font Mono";
    };
    sansSerif = {
      package = pkgs.dejavu_fonts;
      name = "DejaVu Sans";
    };
    serif = {
      package = pkgs.dejavu_fonts;
      name = "DejaVu Serif";
    };
  };

  stylix.targets.chromium.enable = false;
}

