{ inputs }:
let
  systemUsers = import ./users/users.nix { };
  users = systemUsers.users;
  usersWithGuests = systemUsers.usersWithGuests;
in {
  desktop = {
    hostPath = ./hosts/desktop;
    desktop = "hyprland";
    enableThemeSpecialisations = true;
    enableDesktopSpecialisations = true;
    desktopSpecialisations = [ "sway" "river" ];
    hostName = "desktop";
    users = usersWithGuests;
  };

  wsl = {
    hostPath = ./hosts/wsl;
    desktop = "none";
    additionalModules = [ inputs.nixos-wsl.nixosModules.wsl ];
    hostName = "nixos-wsl";
    users = users;
  };

  media = {
    hostPath = ./hosts/media;
    desktop = "gnome";
    hostName = "media";
    users = users;
  };

  thinkpad = {
    hostPath = ./hosts/thinkpad;
    desktop = "river";
    hostName = "thinkpad";
    enableThemeSpecialisations = true;
    additionalModules =
      [ inputs.nixos-hardware.nixosModules.lenovo-thinkpad-t490 ];
    users = users;
  };
}
