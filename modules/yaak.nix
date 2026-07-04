{
  homeConfig = { config, lib, pkgs, userProfiles ? [ ], ... }:
    let cfg = config.yaak;
    in {
      options.yaak = { enable = lib.mkEnableOption "Yaak configuration"; };

      config = lib.mkMerge [
        (lib.mkIf (builtins.elem "backend-developer" userProfiles) {
          yaak.enable = true;
        })
        (lib.mkIf cfg.enable { home.packages = with pkgs; [ yaak ]; })
      ];
    };
}
