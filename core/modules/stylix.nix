{ config, lib, pkgs, ... }:

let cfg = config.stylixTheming;
in {
  options.stylixTheming = {
    enable = lib.mkEnableOption "Stylix theming support";

    image = lib.mkOption {
      type = lib.types.path;
      default = "";
      description = "Path to the wallpaper image.";
    };

    polarity = lib.mkOption {
      type = lib.types.enum [ "light" "dark" ];
      default = "dark";
      description = "Theme polarity (light or dark).";
    };

    base16Scheme = lib.mkOption {
      type = lib.types.path;
      default = "${pkgs.base16-schemes}/share/themes/tokyo-night-dark.yaml";
      description = "Base16 color scheme file.";
    };

    opacity = lib.mkOption {
      type = lib.types.attrsOf lib.types.float;
      default = {
        desktop = 0.5;
        terminal = 0.9;
      };
      description = "Opacity settings for desktop and terminal.";
    };

    cursor = lib.mkOption {
      type = lib.types.attrs;
      default = {
        package = pkgs.adwaita-icon-theme;
        name = "Adwaita";
        size = 24;
      };
      description = "Cursor theme settings.";
    };

    fontSizes = lib.mkOption {
      type = lib.types.attrsOf lib.types.int;
      default = {
        applications = 12;
        terminal = 12;
        desktop = 8;
        popups = 8;
      };
      description = "Font sizes for various UI elements.";
    };

    fonts = lib.mkOption {
      type = lib.types.attrs;
      default = {
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
      description = "Font families for monospace, sans-serif, and serif.";
    };
  };

  config = lib.mkIf cfg.enable {
    stylix.enable = true;
    stylix.enableReleaseChecks = false;
    stylix.image = cfg.image;
    stylix.polarity = cfg.polarity;
    stylix.base16Scheme = cfg.base16Scheme;
    stylix.opacity = cfg.opacity;
    stylix.cursor = cfg.cursor;
    stylix.fonts = cfg.fonts // { sizes = cfg.fontSizes; };
    stylix.targets.chromium.enable = false;
  };
}
