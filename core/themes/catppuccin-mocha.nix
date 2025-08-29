{ inputs, pkgs, ... }: {
  name = "catppuccin-mocha";
  wallpaper = "${inputs.dotfiles}/backgrounds/catppuccintotoro.png";
  base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
  themeColors = {
    active_border = "rgb(cba6f7)"; # mauve
    inactive_border = "rgb(6c7086)"; # overlay0
    locked_active = "rgb(f9e2af)"; # yellow
    locked_inactive = "rgb(585b70)"; # surface2
    text = "rgb(cdd6f4)"; # text
    groupbar_active = "rgb(cba6f7)"; # mauve
    groupbar_inactive = "rgb(313244)"; # surface0
    groupbar_locked_active = "rgb(f9e2af)"; # yellow
    groupbar_locked_inactive = "rgb(585b70)"; # surface2
  };
}
