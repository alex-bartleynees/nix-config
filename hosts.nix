{ inputs }:
let
  systemUsers = import ./users/users.nix { };
  users = systemUsers.users;
  macUsers = systemUsers.macUsers;
in {
  desktop = {
    desktop = "hyprland";
    themeName = "everforest";
    enableThemeSpecialisations = true;
    enableDesktopSpecialisations = true;
    desktopSpecialisations = [ "niri" "mangowc" ];
    systemProfiles = [ "gaming-workstation" ];
    hostName = "desktop";
    users = users;
    additionalUserProfiles = {
      alexbn.profiles =
        [ "vscode-developer" "rider-developer" "backend-developer" ];
      alexbn-work.profiles =
        [ "vscode-developer" "rider-developer" "backend-developer" "work" ];
    };
  };

  wsl = {
    desktop = "none";
    hostName = "nixos-wsl";
    users = users;
    additionalUserProfiles = { alexbn.profiles = [ "rider-developer" ]; };
    stateVersion = "24.05";
    systemProfiles = [ "wsl" ];
  };

  media = {
    desktop = "gnome";
    hostName = "media";
    users = users;
    systemProfiles = [ "media-server" ];
  };

  thinkpad = {
    desktop = "niri";
    hostName = "thinkpad";
    enableThemeSpecialisations = true;
    additionalModules =
      [ inputs.nixos-hardware.nixosModules.lenovo-thinkpad-t490 ];
    users = users;
    additionalUserProfiles = {
      alexbn.profiles = [ "vscode-developer" "rider-developer" ];
    };
    systemProfiles = [ "linux-laptop" ];
  };

  macbook = {
    desktop = "none";
    hostName = "macbook";
    users = macUsers;
    isDarwin = true;
    system = "aarch64-darwin";
    systemProfiles = [ "macbook" ];
  };
}
