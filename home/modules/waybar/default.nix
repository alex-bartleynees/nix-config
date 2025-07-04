{ pkgs, inputs, theme, lib, config, ... }: {
  home.packages = with pkgs; [ waybar ];

  home.file = {
    ".config/waybar" = {
      source = "${inputs.dotfiles}/themes/${theme}/waybar";
      recursive = true;
    };
  };
}
