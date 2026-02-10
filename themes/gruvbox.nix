{ inputs, pkgs, ... }: {
  name = "gruvbox";
  wallpaper = "${inputs.dotfiles}/backgrounds/gruvbox.jpg";
  base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-hard.yaml";
  themeColors = {
    active_border = "#fe8019"; # orange
    inactive_border = "#665c54"; # bg3
    locked_active = "#fabd2f"; # yellow
    locked_inactive = "#3c3836"; # bg1
    text = "#ebdbb2"; # fg
    groupbar_active = "#fe8019"; # orange
    groupbar_inactive = "#1d2021"; # bg0_hard
    groupbar_locked_active = "#fabd2f"; # yellow
    groupbar_locked_inactive = "#3c3836"; # bg1
  };
  codeTheme = "Gruvbox Dark Hard";
  ghosttyTheme = "Gruvbox Dark Hard";
  chromeThemeExtensionId = "giokfhncgfjkoamdbhfhfhgpikaioccc";
  obsidianTheme = "Obsidian gruvbox";
  zellijTheme = "gruvbox-dark";
}
