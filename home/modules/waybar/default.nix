{ pkgs, inputs, theme, lib, config, ... }: {
  home.packages = with pkgs; [ waybar ];

  # Always install dotfiles waybar config for sway but in a separate directory
  home.file = {
    ".config/waybar-sway" = {
      source = "${inputs.dotfiles}/themes/${theme}/waybar";
      recursive = true;
    };
  };
}
