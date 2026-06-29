{
  nixosConfig = { pkgs, lib, monitors, ... }:
    let
      toGnomeRotation = t:
        if t == 90 then
          "right"
        else if t == 180 then
          "upside-down"
        else if t == 270 then
          "left"
        else
          "normal";

      renderMonitor = m: ''
        <monitor>
          <monitorspec>
            <connector>${m.name}</connector>
            ${
              lib.optionalString (m.vendor != "") "<vendor>${m.vendor}</vendor>"
            }
            ${
              lib.optionalString (m.product != "")
              "<product>${m.product}</product>"
            }
            ${
              lib.optionalString (m.serial != "") "<serial>${m.serial}</serial>"
            }
          </monitorspec>
          <mode>
            <width>${toString m.width}</width>
            <height>${toString m.height}</height>
            <rate>${toString (builtins.floor m.refresh)}.000</rate>
          </mode>
        </monitor>'';

      renderLogicalMonitor = m: ''
        <logicalmonitor>
          <x>${toString m.x}</x>
          <y>${toString m.y}</y>
          <scale>${toString m.scale}</scale>
          ${lib.optionalString m.primary "<primary>yes</primary>"}
          ${
            lib.optionalString (m.transform != 0) ''
              <transform>
                <rotation>${toGnomeRotation m.transform}</rotation>
                <flipped>no</flipped>
              </transform>''
          }
          ${renderMonitor m}
        </logicalmonitor>'';

      monitorsXml = ''
        <monitors version="2">
        <configuration>
          <layoutmode>physical</layoutmode>
        ${lib.concatMapStringsSep "\n" renderLogicalMonitor monitors}
        </configuration>
        </monitors>'';
    in {
      imports = [ ./common/wayland.nix ];
      services.desktopManager = { gnome.enable = true; };

      services.displayManager = { gdm.enable = true; };

      services.gnome = {
        core-apps.enable = true;
        gnome-keyring.enable = true;
      };

      programs.dconf.enable = true;

      environment.systemPackages = with pkgs; [
        gnome-tweaks
        dconf-editor
        gnome-shell-extensions
      ];

      services.upower.enable = true;
      services.accounts-daemon.enable = true;

      system.nixos.tags = [ "gnome" ];

      stylix.targets.qt.enable = false;

      xdg.portal = {
        enable = true;
        wlr.enable = true;
        extraPortals = with pkgs; [
          xdg-desktop-portal-gtk
          xdg-desktop-portal-gnome
        ];
      };

      systemd.tmpfiles.rules = [
        "L+ /run/gdm/.config/monitors.xml - - - - ${
          pkgs.writeText "gdm-monitors.xml" monitorsXml
        }"
      ];
    };

  homeConfig = { ... }: {
    ghostty = {
      enable = true;
      theme = theme.ghosttyTheme or theme.name;
      windowDecoration = true;
    };

    obsidian = {
      enable = true;
      theme = theme.obsidianTheme or "Default";
    };

    brave = {
      enable = true;
      themeExtensionId = theme.chromeThemeExtensionId;
    };

    stylix.targets.vscode.enable = false;
  };
}
