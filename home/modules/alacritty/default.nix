{ config, pkgs, lib, ... }:

let
  alacritty-theme = pkgs.fetchFromGitHub {
    owner = "alacritty";
    repo = "alacritty-theme";
    rev = "95a7d695605863ede5b7430eb80d9e80f5f504bc";
    sha256 = "sha256-D37MQtNS20ESny5UhW1u6ELo9czP4l+q0S8neH7Wdbc=";
  };
in {
  programs.alacritty = {
    enable = true;

    settings = {
      env = { TERM = "xterm-256color"; };

      window = { opacity = 0.9; };

      font = {
        normal = {
          family = lib.mkDefault "JetBrainsMonoNL Nerd Font Mono";
          style = "Regular";
        };
        bold = { style = "Bold"; };
        italic = { style = "Italic"; };
        bold_italic = { style = "Bold Italic"; };
      };

      selection = { save_to_clipboard = true; };

      general.import = [ "${alacritty-theme}/themes/tokyo-night.toml" ];
    };
  };
}

