{
  nixosConfig = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      xfce4-whiskermenu-plugin
      xfce4-pulseaudio-plugin
      xfce4-cpugraph-plugin
      xfce4-battery-plugin
      lightdm-gtk-greeter
      elementary-xfce-icon-theme
    ];

    services.xserver = {
      enable = true;
      desktopManager.xfce.enable = true;

      displayManager.lightdm = {
        enable = true;
        greeters.gtk = { enable = true; };
      };
    };

    services.picom = {
      enable = true;
      fade = true;
      inactiveOpacity = 0.7;
      shadow = true;
      fadeDelta = 4;
      backend = "glx";
      vSync = true;
    };
  };

  homeConfig = { theme, ... }: {
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

