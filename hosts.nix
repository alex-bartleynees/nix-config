{ inputs }:
let
  systemUsers = import ./users/users.nix { };
  users = systemUsers.users;
  macUsers = systemUsers.macUsers;
in {
  desktop = {
    desktop = "hyprland";
    themeName = "gruvbox";
    enableThemeSpecialisations = true;
    enableDesktopSpecialisations = true;
    desktopSpecialisations = [ ];
    systemProfiles = [ "gaming-workstation" ];
    hostName = "desktop";
    users = users;
    additionalUserProfiles = {
      alexbn.profiles = [
        "vscode-developer"
        "rider-developer"
        "backend-developer"
        "host-desktop"
      ];
      alexbn-work.profiles = [
        "vscode-developer"
        "rider-developer"
        "backend-developer"
        "work"
        "host-desktop"
      ];
    };
  };

  wsl = {
    desktop = "none";
    hostName = "nixos-wsl";
    users = users;
    additionalUserProfiles = {
      alexbn.profiles = [ "rider-developer" "host-wsl" ];
    };
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
      alexbn.profiles =
        [ "vscode-developer" "rider-developer" "host-thinkpad" ];
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
    additionalUserProfiles = { alexbn.profiles = [ "host-macbook" ]; };
  };
}
