{ inputs, pkgs, ... }: {
  name = "rose-pine";
  wallpaper = "${inputs.dotfiles}/backgrounds/min-linux.jpg";
  base16Scheme = "${pkgs.base16-schemes}/share/themes/rose-pine.yaml";
  themeColors = {
    active_border = "#c4a7e7"; # iris
    inactive_border = "#6e6a86"; # muted
    locked_active = "#f6c177"; # gold
    locked_inactive = "#26233a"; # overlay
    text = "#e0def4"; # text
    groupbar_active = "#c4a7e7"; # iris
    groupbar_inactive = "#191724"; # base
    groupbar_locked_active = "#f6c177"; # gold
    groupbar_locked_inactive = "#26233a"; # overlay
  };
  codeTheme = "Rosé Pine";
  ghosttyTheme = "Rose Pine";
  chromeThemeExtensionId = "noimedcjdohhokijigpfcbjcfcaaahej";
  obsidianTheme = "Rose Pine";
  zellijTheme = "dracula"; 
}
