{ pkgs, users, lib, ... }: {
  services.greetd = {
    enable = true;
    settings = lib.mkMerge [
      {
        default_session = {
          command =
            "${pkgs.cage}/bin/cage -s -- ${pkgs.moonlight-qt}/bin/moonlight";
        };
      }
      (lib.mkIf (builtins.length users == 1) {
        initial_session = {
          command =
            "${pkgs.cage}/bin/cage -s -- ${pkgs.moonlight-qt}/bin/moonlight";
          user = (builtins.head users).username;
        };
      })
    ];
  };
}
