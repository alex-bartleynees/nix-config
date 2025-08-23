{ config, lib, pkgs, ... }: {
  services.greetd = {
    enable = true;
    settings = {
      initial_session = {
        command = "cage ${pkgs.moonlight-qt}/bin/moonlight";
        user = "alexbn";
      };
    };
  };
}
