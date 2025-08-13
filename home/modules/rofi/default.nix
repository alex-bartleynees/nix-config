{ pkgs, inputs, theme, ... }: {
  home.packages = with pkgs; [ rofi-wayland ];

  home.file = {
    ".config/rofi" = {
      source = "${inputs.dotfiles}/configs/rofi-custom";
      recursive = true;
    };
  };

  home.file.".local/bin/powermenu" = {
    source = "${inputs.dotfiles}/configs/rofi-custom/powermenu.sh";
    executable = true;
  };
  home.sessionPath = [ "$HOME/.local/bin" ];

}
