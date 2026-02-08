{ config, lib, users, pkgs, ... }:
let cfg = config.virtualisation;
in {
  options.virtualisation = {
    enable = lib.mkEnableOption "Virtualisation support";

    user = lib.mkOption {
      type = lib.types.str;
      default = (builtins.head users).username;
      description = "User to add to the vboxusers group";
    };
  };

  config = lib.mkIf cfg.enable {
    # Virtualisation
    virtualisation.libvirtd.enable = true;
    programs.virt-manager.enable = true;
    users.users.${cfg.user}.extraGroups = [ "libvirtd" ];
    networking.firewall.trustedInterfaces = [ "virbr0" ];

    environment.systemPackages = with pkgs; [ vagrant dnsmasq ];
  };

}
