{ pkgs, inputs, theme, desktop ? "hyprland", ... }:
let
  waybarRepo = inputs.dotfiles;

  waybarConfig =
    pkgs.runCommand "waybar-config" { buildInputs = [ pkgs.jq ]; } ''
      mkdir -p $out
      cd ${waybarRepo}

      cd configs/waybar  

      bash build.sh ${desktop} ${theme.name} $out
    '';
in {
  programs.waybar = { enable = true; };

  home.file.".config/waybar" = {
    source = waybarConfig;
    recursive = true;
  };
}
