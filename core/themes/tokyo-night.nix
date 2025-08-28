{ inputs, pkgs, ... }: {
  name = "tokyo-night";
  wallpaper =
    "${inputs.dotfiles}/backgrounds/3--Milad-Fakurian-Abstract-Purple-Blue.jpg";
  base16Scheme = "${pkgs.base16-schemes}/share/themes/tokyo-night-storm.yaml";
  themeColors = {
    active_border = "rgb(7aa2f7)"; # blue
    inactive_border = "rgb(565f89)"; # comment
    locked_active = "rgb(e0af68)"; # yellow
    locked_inactive = "rgb(3b4261)"; # bg_highlight
    text = "rgb(c0caf5)"; # foreground
    groupbar_active = "rgb(7aa2f7)"; # blue
    groupbar_inactive = "rgb(24283b)"; # bg_dark
    groupbar_locked_active = "rgb(e0af68)"; # yellow
    groupbar_locked_inactive = "rgb(3b4261)"; # bg_highlight
  };
}
