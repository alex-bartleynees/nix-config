{ config, pkgs, lib, ... }:
{
	environment.sessionVariables = {
			WLR_NO_HARDWARE_CURSORS = "1";
			NIXOS_OZONE_WL = "1";
			__GLX_VENDOR_LIBRARY_NAME = "nvidia";
			WLR_RENDERER = "vulkan";
			XDG_SESSION_TYPE = "wayland";
                        GBM_BACKEND = "nvidia-drm";
                        GTK_THEME = "Adwaita:dark";
                        QT_STYLE_OVERRIDE = "adwaita-dark";
                          MOZ_USE_XINPUT2 = "1";
  # Force dark mode for websites
  GTK_USE_PORTAL = "1";
  GSETTINGS_SCHEMA_DIR = "/run/current-system/sw/share/gsettings-schemas/";
		};

	xdg.portal = {
		enable = true;
		wlr.enable = true;
		extraPortals = [pkgs.xdg-desktop-portal-gtk pkgs.xdg-desktop-portal-wlr];
		config.common.default = ["wlr"];
		xdgOpenUsePortal = true;
	};
}
