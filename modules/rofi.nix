# homeModule: true
{ config, pkgs, lib, inputs, ... }:
let cfg = config.rofi;
in {
  options.rofi = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Rofi application launcher";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [ rofi ];

    home.file = {
      ".config/rofi" = {
        source = "${inputs.dotfiles}/configs/rofi-custom";
        recursive = true;
      };
    };

    home.file.".local/bin/powermenu" = {
      source = "${inputs.dotfiles}/configs/rofi-custom/scripts/powermenu.sh";
      executable = true;
    };

    home.file.".local/bin/themeselector" = {
      source =
        "${inputs.dotfiles}/configs/rofi-custom/scripts/themeselector.sh";
      executable = true;
    };

    home.file.".local/bin/wallpaper" = {
      source = "${inputs.dotfiles}/configs/rofi-custom/scripts/wallpaper.sh";
      executable = true;
    };

    home.file.".local/bin/keybindings" = {
      source = "${inputs.dotfiles}/configs/rofi-custom/scripts/keybindings.sh";
      executable = true;
    };

    home.sessionPath = [ "$HOME/.local/bin" ];
  };
}
