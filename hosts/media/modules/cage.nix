{ config, lib, pkgs, ... }: {
  services.cage = {
    enable = true;
    user = "alexbn";
    program = "${pkgs.moonlight-qt}/bin/moonlight";
  };
}
