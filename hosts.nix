{ inputs }:
let
  systemUsers = import ./users/users.nix { };
  users = systemUsers.users;
  usersWithGuests = systemUsers.usersWithGuests;
  macUsers = systemUsers.macUsers;
in {
  desktop = {
    hostPath = ./hosts/desktop;
    desktop = "hyprland";
    themeName = "everforest";
    enableThemeSpecialisations = true;
    enableDesktopSpecialisations = true;
    desktopSpecialisations = [ "sway" "river" "cosmic" ];
    hostName = "desktop";
    users = usersWithGuests;
    additionalUserProfiles = {
      alexbn.profiles =
        [ "vscode-developer" "rider-developer" "backend-developer" "work" ];
    };
  };

  wsl = {
    hostPath = ./hosts/wsl;
    desktop = "none";
    additionalModules = [ inputs.nixos-wsl.nixosModules.wsl ];
    hostName = "nixos-wsl";
    users = users;
    additionalUserProfiles = { alexbn.profiles = [ "rider-developer" ]; };
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
    additionalUserProfiles = {
      alexbn.profiles = [ "vscode-developer" "rider-developer" ];
    };
  };

  macbook = {
    hostPath = ./hosts/macbook;
    desktop = "none";
    hostName = "macbook";
    users = macUsers;
    isDarwin = true;
    system = "aarch64-darwin";
  };
}
