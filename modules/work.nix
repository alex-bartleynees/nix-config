{
  homeConfig = { config, lib, pkgs, userProfiles ? [ ], ... }:
    let cfg = config.work;
    in {
      options.work = { enable = lib.mkEnableOption "Work configuration"; };

      config = lib.mkMerge [
        (lib.mkIf (builtins.elem "work" userProfiles) { work.enable = true; })
        (lib.mkIf cfg.enable {
          home.packages = with pkgs; [
            teams-for-linux
            openfortivpn
            openfortivpn-webview
          ];
        })
      ];
    };
}
