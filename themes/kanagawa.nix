{ inputs, pkgs, ... }: {
  name = "kanagawa";
  wallpaper = "${inputs.dotfiles}/backgrounds/kanagawa.jpg";
  base16Scheme = "${pkgs.base16-schemes}/share/themes/kanagawa.yaml";
  themeColors = {
    active_border = "#7E9CD8"; # crystalBlue
    inactive_border = "#54546D"; # sumiInk4
    locked_active = "#C0A36E"; # carpYellow
    locked_inactive = "#16161D"; # sumiInk1
    text = "#DCD7BA"; # fujiWhite
    groupbar_active = "#7E9CD8"; # crystalBlue
    groupbar_inactive = "#1F1F28"; # sumiInk2
    groupbar_locked_active = "#C0A36E"; # carpYellow
    groupbar_locked_inactive = "#16161D"; # sumiInk1
  };
  codeTheme = "Kanagawa Wave";
  ghosttyTheme = "Kanagawa Wave";
  chromeThemeExtensionId = "djnghjlejbfgnbnmjfgbdaeafbiklpha";
  obsidianTheme = "Kanagawa";
  zellijTheme = "kanagawa";
}
