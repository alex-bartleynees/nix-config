{ config, lib, ... }:
let cfg = config.technitiumDns;
in {
  options.technitiumDns = {
    enable = lib.mkEnableOption "Technitium DNS server";
    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Open firewall ports for DNS (53) and web interface (5380)";
    };
  };

  config = lib.mkIf cfg.enable {
    services.technitium-dns-server = {
      enable = true;
      openFirewall = cfg.openFirewall;
      firewallTCPPorts = [ 5380 ];
    };
  };
}
