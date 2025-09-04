{ inputs, pkgs, ... }: {
  name = "everforest";
  wallpaper = "${inputs.dotfiles}/backgrounds/fog_forest_2.jpg";
  base16Scheme = "${pkgs.base16-schemes}/share/themes/everforest.yaml";
  themeColors = {
    active_border = "#A7C080"; # everforest green - primary accent
    inactive_border = "#475258"; # everforest bg3 - subtle separator
    locked_active = "#DBBC7F"; # everforest yellow - attention/warning
    locked_inactive = "#343F44"; # everforest bg1 - inactive state
    text = "#D3C6AA"; # everforest fg - main text color
    groupbar_active = "#A7C080"; # everforest green - primary accent
    groupbar_inactive = "#2D353B"; # everforest bg0 - default background
    groupbar_locked_active = "#DBBC7F"; # everforest yellow - attention/warning
    groupbar_locked_inactive = "#343F44"; # everforest bg1 - inactive state
  };
  codeTheme = "Everforest";
  ghosttyTheme = "Everforest Dark - Hard";
  chromeThemeExtensionId = "dlcadbmcfambdjhecipbnolmjchgnode";
}
