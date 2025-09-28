{ lib, ... }:
{
  options.profiles = with lib; {
    base = mkEnableOption "Base profile for all machines";
    linux-desktop = mkEnableOption "Linux desktop profile with GUI and persistence";
    gaming-workstation = mkEnableOption "Gaming workstation profile with high-end hardware support";
    media-server = mkEnableOption "Media server profile optimized for streaming and headless operation";
  };
}