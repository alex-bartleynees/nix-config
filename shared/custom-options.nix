{ lib, ... }: {
  options.myUsers = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule {
      options.git = lib.mkOption {
        type = lib.types.attrs;
        default = { };
      };
    });
    default = { };
  };
}
