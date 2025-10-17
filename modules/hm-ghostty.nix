{ config, pkgs, lib, ... }:
let cfg = config.ghostty;
in {
  options.ghostty = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Ghostty terminal configuration.";
    };

    theme = lib.mkOption {
      type = lib.types.str;
      default = "default";
      description = "Theme name for Ghostty.";
    };

    backgroundOpacity = lib.mkOption {
      type = lib.types.float;
      default = 0.9;
      description = "Background opacity for Ghostty window.";
    };

    windowDecoration = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable window decorations for Ghostty.";
    };

    extraConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Extra configuration for Ghostty.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs;
      [ (if pkgs.stdenv.isDarwin then ghostty-bin else ghostty) ];

    home.file.".config/ghostty/config".text = ''
      background-opacity=${toString cfg.backgroundOpacity}
      window-decoration=${if cfg.windowDecoration then "true" else "false"}
      theme=${cfg.theme}
      keybind=global:alt+backquote=toggle_quick_terminal
      ${cfg.extraConfig}
    '';
  };
}
