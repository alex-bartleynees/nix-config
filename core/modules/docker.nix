{ config, lib, ... }:
let cfg = config.docker;
in {
  options.docker = { enable = lib.mkEnableOption "Docker support"; };

  config = lib.mkIf cfg.enable {
    virtualisation.docker = {
      enable = true;
      enableOnBoot = true;
      autoPrune.enable = true;
    };
  };
}
