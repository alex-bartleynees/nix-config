{ inputs }:
let
  systemUsers = import ./users/users.nix { };
  users = systemUsers.users;
  macUsers = systemUsers.macUsers;
in {
  desktop = {
    desktop = "mangowc";
    themeName = "gruvbox";
    enableThemeSpecialisations = true;
    enableDesktopSpecialisations = true;
    desktopSpecialisations =
      [ "sway" "gnome" "cosmic" "kde" "hyprland" "river" "niri" ];
    systemProfiles = [ "gaming-workstation" ];
    hostName = "desktop";
    users = users;
    monitors = [
      {
        name = "DP-2";
        description = "AOC U27G4 10GR2HA001383";
        vendor = "AOC";
        product = "U27G4";
        serial = "10GR2HA001383";
        width = 3840;
        height = 2160;
        refresh = 160.0;
        x = 0;
        y = 0;
        scale = 1.5;
        vrr = true;
        transform = 0;
        hdr = false;
        sdrBrightness = 1.0;
        sdrSaturation = 1.0;
        primary = true;
      }
      {
        name = "HDMI-A-1";
        description = "LG Electronics 27GL850 006NTDVG0786";
        vendor = "LG Electronics";
        product = "27GL850";
        serial = "006NTDVG0786";
        width = 2560;
        height = 1440;
        refresh = 100.0;
        x = 2560;
        y = 0;
        scale = 1.0;
        vrr = true;
        transform = 90;
        hdr = false;
        sdrBrightness = 1.0;
        sdrSaturation = 1.0;
        primary = false;
      }
    ];
    additionalUserProfiles = {
      alexbn.profiles = [
        "vscode-developer"
        "rider-developer"
        "backend-developer"
        "host-desktop"
        "reader"
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
    desktop = "hyprland";
    hostName = "media";
    users = users;
    systemProfiles = [ "media-server" ];
    monitors = [{
      name = "HDMI-A-1";
      description = "";
      vendor = "";
      product = "";
      serial = "";
      width = 2560;
      height = 1440;
      refresh = 120.0;
      x = 0;
      y = 0;
      scale = 1.0;
      vrr = true;
      transform = 0;
      hdr = true;
      sdrBrightness = 1.2;
      sdrSaturation = 0.98;
      primary = true;
    }];
    additionalUserProfiles = { alexbn.profiles = [ "host-media" ]; };
  };

  thinkpad = {
    desktop = "niri";
    hostName = "thinkpad";
    enableThemeSpecialisations = true;
    additionalModules =
      [ inputs.nixos-hardware.nixosModules.lenovo-thinkpad-t490 ];
    users = users;
    monitors = [{
      name = "eDP-1";
      description = "";
      vendor = "";
      product = "";
      serial = "";
      width = 1920;
      height = 1080;
      refresh = 60.0;
      x = 0;
      y = 0;
      scale = 1.0;
      vrr = false;
      transform = 0;
      hdr = false;
      sdrBrightness = 1.0;
      sdrSaturation = 1.0;
      primary = true;
    }];
    additionalUserProfiles = {
      alexbn.profiles =
        [ "vscode-developer" "rider-developer" "host-thinkpad" "reader" ];
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
