{ inputs }: {
  desktop = {
    hostPath = ./hosts/desktop;
    desktop = "hyprland";
    enableThemeSpecialisations = true;
    enableDesktopSpecialisations = true;
    desktopSpecialisations = [ "sway" "river" ];
  };

  wsl = {
    hostPath = ./hosts/wsl;
    desktop = "none";
    additionalModules = [ inputs.nixos-wsl.nixosModules.wsl ];
  };

  media = {
    hostPath = ./hosts/media;
    desktop = "gnome";
  };

  thinkpad = {
    hostPath = ./hosts/thinkpad;
    desktop = "river";
    enableThemeSpecialisations = true;
    additionalModules =
      [ inputs.nixos-hardware.nixosModules.lenovo-thinkpad-t490 ];
  };
}
