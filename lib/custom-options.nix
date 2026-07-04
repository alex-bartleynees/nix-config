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
  };
}
