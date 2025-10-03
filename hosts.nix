{ inputs }:
let
  systemUsers = import ./users/users.nix { };
  users = systemUsers.users;
  usersWithGuests = systemUsers.usersWithGuests;
  macUsers = systemUsers.macUsers;
in {
  desktop = {
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
    desktop = "none";
    additionalModules = [ inputs.nixos-wsl.nixosModules.wsl ];
    hostName = "nixos-wsl";
    users = users;
    additionalUserProfiles = { alexbn.profiles = [ "rider-developer" ]; };
    stateVersion = "24.05";
  };

  media = {
    desktop = "gnome";
    hostName = "media";
    users = users;
  };

  thinkpad = {
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
    desktop = "none";
    hostName = "macbook";
    users = macUsers;
    isDarwin = true;
    system = "aarch64-darwin";
  };
}
