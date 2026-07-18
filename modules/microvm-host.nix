{ config, lib, self, ... }:
let cfg = config.microvmHost;
in {
  options.microvmHost = {
    enable = lib.mkEnableOption "MicroVM host support";

    externalInterface = lib.mkOption {
      type = lib.types.str;
      default = "wlp7s0";
      description = "Host interface to masquerade VM traffic through (NAT)";
    };

    vms = lib.mkOption {
      description = "MicroVMs to host, keyed by name.";
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          tapId = lib.mkOption { type = lib.types.str; };
          gateway = lib.mkOption { type = lib.types.str; };
          autostart = lib.mkOption {
            type = lib.types.bool;
            default = true;
          };
        };
      });
      default = { };
    };
  };

  config = lib.mkMerge [
    { microvm.host.enable = cfg.enable; }

    (lib.mkIf cfg.enable {
      microvm.vms = lib.mapAttrs (name: vm: {
        flake = self;
        inherit (vm) autostart;
      }) cfg.vms;

      networking.interfaces = lib.mapAttrs' (name: vm:
        lib.nameValuePair vm.tapId {
          ipv4.addresses = [{
            address = vm.gateway;
            prefixLength = 24;
          }];
        }) cfg.vms;

      networking.networkmanager.unmanaged =
        lib.mapAttrsToList (name: vm: vm.tapId) cfg.vms;

      networking.nat = {
        enable = true;
        internalInterfaces = lib.mapAttrsToList (name: vm: vm.tapId) cfg.vms;
        externalInterface = cfg.externalInterface;
      };
    })
  ];
}
