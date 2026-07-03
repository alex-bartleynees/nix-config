{
  homeConfig = { config, pkgs, lib, userProfiles ? [ ], ... }:
    let cfg = config.rider;
    in {
      options.rider = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable JetBrains Rider IDE";
        };
      };

      config = lib.mkMerge [
        (lib.mkIf (builtins.elem "rider-developer" userProfiles) {
          rider.enable = true;
        })
        (lib.mkIf cfg.enable {
          home.packages = with pkgs; [ jetbrains.rider ];
        })
      ];
    };
}
