{ inputs }: {
  desktop = {
    hostPath = ./hosts/desktop;
    desktop = "hyprland";
    enableSpecialisations = true;
    enableThemeSpecialisations = true;
  };

  wsl = {
    hostPath = ./hosts/wsl;
    desktop = "none";
    enableSpecialisations = false;
    enableThemeSpecialisations = false;
    additionalModules = [ inputs.nixos-wsl.nixosModules.wsl ];
  };

  media = {
    hostPath = ./hosts/media;
    desktop = "gnome";
    enableSpecialisations = false;
    enableThemeSpecialisations = false;
  };

  thinkpad = {
    hostPath = ./hosts/thinkpad;
    desktop = "river";
    enableSpecialisations = false;
    enableThemeSpecialisations = true;
    additionalModules =
      [ inputs.nixos-hardware.nixosModules.lenovo-thinkpad-t490 ];
  };
}
