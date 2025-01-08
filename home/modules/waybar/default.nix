{ pkgs, inputs, theme, ... }: {
  home.packages = with pkgs; [ waybar ];

  home.file = {
    ".config/waybar" = {
      source = "${inputs.dotfiles}/themes/${theme}/waybar";
      recursive = true;
    };
  };
}
