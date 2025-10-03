{ config, pkgs, lib, ... }:
let
  cfg = config.alacritty;

  alacritty-theme = pkgs.fetchFromGitHub {
    owner = "alacritty";
    repo = "alacritty-theme";
    rev = "95a7d695605863ede5b7430eb80d9e80f5f504bc";
    sha256 = "sha256-D37MQtNS20ESny5UhW1u6ELo9czP4l+q0S8neH7Wdbc=";
  };
in {
  options.alacritty = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Alacritty terminal configuration.";
    };

    theme = lib.mkOption {
      type = lib.types.str;
      default = "tokyo-night";
      description = "Theme name from alacritty-theme repository.";
    };

    opacity = lib.mkOption {
      type = lib.types.float;
      default = 0.9;
      description = "Window opacity for Alacritty.";
    };

    fontFamily = lib.mkOption {
      type = lib.types.str;
      default = "JetBrainsMonoNL Nerd Font Mono";
      description = "Font family for Alacritty.";
    };

    extraSettings = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Extra settings for Alacritty configuration.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.alacritty = {
      enable = true;

      settings = lib.recursiveUpdate {
        env = { TERM = "xterm-256color"; };

        window = { opacity = cfg.opacity; };

        font = {
          normal = {
            family = lib.mkDefault cfg.fontFamily;
            style = "Regular";
          };
          bold = { style = "Bold"; };
          italic = { style = "Italic"; };
          bold_italic = { style = "Bold Italic"; };
        };

        selection = { save_to_clipboard = true; };

        general.import = [ "${alacritty-theme}/themes/${cfg.theme}.toml" ];
      } cfg.extraSettings;
    };
  };
}
