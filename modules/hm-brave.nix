{ config, lib, ... }:
let cfg = config.brave;
in {
  options.brave = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Brave browser configuration.";
    };

    themeExtensionId = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Chrome Web Store extension ID for theme.";
    };

    extraExtensions = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Additional extension IDs to install.";
    };

    defaultExtensions = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable default extensions (Angular Dev Tools, Bitwarden).";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.brave = {
      enable = true;
      extensions = (lib.optionals cfg.defaultExtensions [
        "ienfalfjdbdpebioblfackkekamfmbnh" # angular dev tools
        "nngceckbapebfimnlniiiahkandclblb" # bitwarden
      ]) ++ (lib.optional (cfg.themeExtensionId != "") cfg.themeExtensionId)
        ++ cfg.extraExtensions;
    };
  };
}
