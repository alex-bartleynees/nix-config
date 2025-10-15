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

    networking.firewall = {
      trustedInterfaces = [ "docker0" ];
      extraCommands = ''
        iptables -A INPUT -s 172.17.0.0/16 -j ACCEPT
        iptables -A INPUT -s 172.18.0.0/16 -j ACCEPT
      '';
    };
  };
}
