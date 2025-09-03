{ inputs, pkgs, ... }: {
  name = "catppuccin-mocha";
  wallpaper = "${inputs.dotfiles}/backgrounds/catppuccintotoro.png";
  base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
  themeColors = {
    active_border = "#cba6f7"; # mauve
    inactive_border = "#6c7086"; # overlay0
    locked_active = "#f9e2af"; # yellow
    locked_inactive = "#585b70"; # surface2
    text = "#cdd6f4"; # text
    groupbar_active = "#cba6f7"; # mauve
    groupbar_inactive = "#313244"; # surface0
    groupbar_locked_active = "#f9e2af"; # yellow
    groupbar_locked_inactive = "#585b70"; # surface2
  };
  codeTheme = "Catppuccin Mocha";
  chromeThemeExtensionId = "bkkmolkhemgaeaeggcmfbghljjjoofoh";
}
