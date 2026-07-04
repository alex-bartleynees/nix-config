{ lib, ... }: {
  options.myUsers = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule {
      options = {
        git = lib.mkOption {
          type = lib.types.attrs;
          default = { };
        };
        persistPaths = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
        };
        needsPasswordSecret = lib.mkOption {
          type = lib.types.bool;
          default = false;
        };
        profiles = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description =
            "List of user profiles (e.g. 'work', 'personal'). Auto enables corresponding modules";
        };
      };
    });
    default = { };
  };

  options.myConfig = {
    theme = lib.mkOption {
      type = lib.types.attrs;
      description = "Active theme attrset";
    };
    desktop = lib.mkOption {
      type = lib.types.str;
      default = "none";
      description = "Active desktop";
    };
    monitors = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [ ];
      description = "List of monitor configurations";
    };
    systemProfiles = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "List of system profiles";
    };
  };
}
