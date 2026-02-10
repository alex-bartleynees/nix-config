{ inputs, pkgs, ... }: {
  name = "oxocarbon";
  wallpaper = "${inputs.dotfiles}/backgrounds/matte-black.jpg";
  base16Scheme = "${pkgs.base16-schemes}/share/themes/oxocarbon-dark.yaml";
  themeColors = {
    active_border = "#33b1ff"; # blue
    inactive_border = "#393939"; # bg2
    locked_active = "#08bdba"; # teal
    locked_inactive = "#262626"; # bg1
    text = "#f2f4f8"; # fg
    groupbar_active = "#33b1ff"; # blue
    groupbar_inactive = "#161616"; # bg0
    groupbar_locked_active = "#08bdba"; # teal
    groupbar_locked_inactive = "#262626"; # bg1
  };
  codeTheme = "oxocarbon";
  ghosttyTheme = "Oxocarbon";
  chromeThemeExtensionId = "hpejmncgbammabkkodflfeekpcicfjnk";
  obsidianTheme = "Blackbird";
  zellijTheme = "onedark";
}
