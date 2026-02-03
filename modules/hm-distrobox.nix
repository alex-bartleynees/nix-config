{ config, lib, ... }:
let cfg = config.distrobox;
in {
  options.distrobox = {
    enable = lib.mkEnableOption "Distrobox with docker backend";
  };

  config = lib.mkIf cfg.enable {
    programs.distrobox = {
      enable = true;
      settings = { container_manager = "docker"; };
    };
  };
}
