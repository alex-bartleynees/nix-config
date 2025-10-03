{ lib, ... }: {
  options.profiles = with lib; {
    base = mkEnableOption "Base profile for all machines";
    linux-desktop =
      mkEnableOption "Linux desktop profile with GUI and persistence";
    linux-laptop =
      mkEnableOption "Linux laptop profile with power management optimizations";
    gaming-workstation = mkEnableOption
      "Gaming workstation profile with high-end hardware support";
    media-server = mkEnableOption
      "Media server profile optimized for streaming and headless operation";
    wsl = mkEnableOption
      "Windows Subsystem for Linux profile with WSL specific configurations";
  };
}
