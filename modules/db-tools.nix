{
  homeConfig = { config, lib, pkgs, userProfiles ? [ ], ... }: {
    options.db-tools = {
      enable = lib.mkEnableOption "Database and backup browser tools";
    };

    config = lib.mkMerge [
      (lib.mkIf (builtins.elem "db-tools" userProfiles) {
        db-tools.enable = true;
      })
      (lib.mkIf config.db-tools.enable {
        home.packages = with pkgs; [
          (pkgs.symlinkJoin {
            name = "restic-browser-wrapped";
            paths = [ pkgs.restic-browser ];
            buildInputs = [ pkgs.makeWrapper ];
            postBuild = ''
              wrapProgram $out/bin/Restic-Browser \
                --set WEBKIT_DISABLE_DMABUF_RENDERER 1
            '';
          })
          dbeaver-bin
          restic
        ];
      })
    ];
  };
}
