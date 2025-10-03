{ inputs, pkgs, ... }: {
  name = "nord";
  wallpaper = "${inputs.dotfiles}/backgrounds/nord_scenary.png";
  base16Scheme = "${pkgs.base16-schemes}/share/themes/nord.yaml";
  themeColors = {
    active_border = "#88c0d0"; # nord8 - frost cyan
    inactive_border = "#4c566a"; # nord3 - polar night
    locked_active = "#ebcb8b"; # nord13 - aurora yellow
    locked_inactive = "#3b4252"; # nord1 - polar night
    text = "#eceff4"; # nord6 - snow storm
    groupbar_active = "#88c0d0"; # nord8 - frost cyan
    groupbar_inactive = "#2e3440"; # nord0 - polar night (darkest)
    groupbar_locked_active = "#ebcb8b"; # nord13 - aurora yellow
    groupbar_locked_inactive = "#3b4252"; # nord1 - polar night
  };
  codeTheme = "Nord";
  chromeThemeExtensionId = "abehfkkfjlplnjadfcjiflnejblfmmpj";
}
