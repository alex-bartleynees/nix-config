{ config, lib, pkgs, ... }:
let cfg = config.rgb;
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
      default = "blue";
      description = "OpenRGB profile to use on startup";
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
  };
}
