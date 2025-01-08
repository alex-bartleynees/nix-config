{ pkgs, inputs, theme, ... }: {
  home.packages = with pkgs; [ dunst ];

  home.file = {
    ".config/dunst/dunstrc".source = "${inputs.dotfiles}/configs/dunst/dunstrc";
  };
}
