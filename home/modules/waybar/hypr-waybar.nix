{ pkgs, inputs, theme, lib, config, ... }: {
  home.packages = with pkgs; [ waybar ];

  home.file = {
    ".config/waybar-hypr/config.jsonc" = {
      source = "${inputs.dotfiles}/themes/${theme}/waybar/config-hyprland.jsonc";
    };
    
    ".config/waybar-hypr/style.css" = {
      source = "${inputs.dotfiles}/themes/${theme}/waybar/style.css";
    };
  };
}
