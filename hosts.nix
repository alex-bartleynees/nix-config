{ inputs }: {
  desktop = {
    hostPath = ./hosts/desktop;
    desktop = "hyprland";
    enableThemeSpecialisations = true;
    enableDesktopSpecialisations = true;
    desktopSpecialisations = [ "sway" "river" ];
    hostName = "desktop";
  };

  wsl = {
    hostPath = ./hosts/wsl;
    desktop = "none";
    additionalModules = [ inputs.nixos-wsl.nixosModules.wsl ];
    hostName = "nixos-wsl";
  };

  media = {
    hostPath = ./hosts/media;
    desktop = "gnome";
    hostName = "media";
  };

  thinkpad = {
    hostPath = ./hosts/thinkpad;
    desktop = "river";
    hostName = "thinkpad";
    enableThemeSpecialisations = true;
    additionalModules =
      [ inputs.nixos-hardware.nixosModules.lenovo-thinkpad-t490 ];
  };
}
