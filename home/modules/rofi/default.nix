{ pkgs, inputs, theme, ... }: {
  home.packages = with pkgs; [ rofi-wayland ];

  home.file = {
    ".config/rofi" = {
      source = "${inputs.dotfiles}/configs/rofi";
      recursive = true;
    };
  };

  home.sessionPath = [ "$HOME/.config/rofi/scripts" ];
}
