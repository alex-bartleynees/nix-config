# homeModule: true
{ config, pkgs, lib, ... }:
let cfg = config.rider;
in {
  options.rider = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable JetBrains Rider IDE";
    };
  };

  config =
    lib.mkIf cfg.enable { home.packages = with pkgs; [ jetbrains.rider ]; };
}
