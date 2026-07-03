{
  homeConfig = { config, lib, pkgs, userProfiles ? [ ], ... }:
    let cfg = config.calibre;
    in {
      options.calibre = {
        enable = lib.mkEnableOption "Calibre configuration";
      };

      config = lib.mkMerge [
        (lib.mkIf (builtins.elem "reader" userProfiles) {
          calibre.enable = true;
        })
        (lib.mkIf cfg.enable { home.packages = with pkgs; [ calibre ]; })
      ];
    };
}
