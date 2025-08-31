{ inputs, pkgs, ... }: {
  name = "tokyo-night";
  wallpaper =
    "${inputs.dotfiles}/backgrounds/1-scenery-pink-lakeside-sunset-lake-landscape-scenic-panorama-7680x3215-144.png";
  base16Scheme = "${pkgs.base16-schemes}/share/themes/tokyo-night-storm.yaml";
  themeColors = {
    active_border = "#7aa2f7"; # blue
    inactive_border = "#565f89"; # comment
    locked_active = "#e0af68"; # yellow
    locked_inactive = "#3b4261"; # bg_highlight
    text = "#c0caf5"; # foreground
    groupbar_active = "#7aa2f7"; # blue
    groupbar_inactive = "#24283b"; # bg_dark
    groupbar_locked_active = "#e0af68"; # yellow
    groupbar_locked_inactive = "#3b4261"; # bg_highlight
  };
}
