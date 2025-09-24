{ pkgs, username, ... }: {
  services.greetd = {
    enable = true;
    settings = {
      initial_session = {
        command =
          "${pkgs.cage}/bin/cage -s -- ${pkgs.moonlight-qt}/bin/moonlight";
        user = username;
      };
      default_session = {
        command =
          "${pkgs.cage}/bin/cage -s -- ${pkgs.moonlight-qt}/bin/moonlight";
      };
    };
  };
}
