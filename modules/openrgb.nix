{ config, lib, pkgs, ... }:
let
  cfg = config.rgb;

  no-rgb = pkgs.writeScriptBin "no-rgb" ''
    #!/bin/sh
    NUM_DEVICES=$(${pkgs.openrgb}/bin/openrgb --noautoconnect --list-devices | grep -E '^[0-9]+: ' | wc -l)
    for i in $(seq 0 $(($NUM_DEVICES - 1))); do
      ${pkgs.openrgb}/bin/openrgb --noautoconnect --device $i --mode static --color 000000
    done
  '';
in {
  options.rgb = {
    enable = lib.mkEnableOption "OpenRGB support";

    motherboard = lib.mkOption {
      type = lib.types.enum [ "amd" "intel" ];
      default = "amd";
      description = "Motherboard type for OpenRGB (amd, intel)";
    };

    profile = lib.mkOption {
      type = lib.types.str;
      default = "default";
      description = "OpenRGB profile to use on startup";
    };

    turnOffOnBoot = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Turn off all RGB lighting at boot.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.hardware.openrgb = {
      enable = true;
      motherboard = cfg.motherboard;
    };

    environment.systemPackages = [ pkgs.openrgb-with-all-plugins ];

    systemd.services.openrgb = {
      serviceConfig.ExecStart = lib.mkForce
        "${pkgs.openrgb}/bin/openrgb --server --server-port 6742 --profile ${cfg.profile}";
    };

    systemd.services.no-rgb = lib.mkIf cfg.turnOffOnBoot {
      description = "Turn off all RGB lighting";
      serviceConfig = {
        ExecStart = "${no-rgb}/bin/no-rgb";
        Type = "oneshot";
      };
      wantedBy = [ "multi-user.target" ];
    };
  };
}
