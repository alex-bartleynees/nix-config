# homeModule: true
{ config, pkgs, lib, inputs, theme, ... }:
let cfg = config.waybar;
in {
  options.waybar = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable waybar configuration.";
    };

    desktop = lib.mkOption {
      type = lib.types.str;
      default = "hyprland";
      description = "Desktop environment for waybar configuration.";
    };

    sessionTarget = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description =
        "Systemd session target to bind the waybar service to. If null, no service is created.";
    };

    configSource = lib.mkOption {
      type = lib.types.str;
      default = "dotfiles";
      description = "Source for waybar configuration (dotfiles or custom).";
    };

    customConfigPath = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description =
        "Custom path for waybar configuration when not using dotfiles.";
    };
  };

  config = lib.mkIf cfg.enable (let
    waybarRepo = inputs.dotfiles;

    waybarConfig = if cfg.configSource == "dotfiles" then
      pkgs.runCommand "waybar-config" { buildInputs = [ pkgs.jq ]; } ''
        mkdir -p $out
        cd ${waybarRepo}

        cd configs/waybar

        bash build.sh ${cfg.desktop} ${theme.name} $out
      ''
    else
      cfg.customConfigPath;
  in {
    programs.waybar = { enable = true; };

    home.file.".config/waybar" = lib.mkIf (waybarConfig != null) {
      source = waybarConfig;
      recursive = true;
    };

    systemd.user.services.waybar = lib.mkIf (cfg.sessionTarget != null) {
      Unit = {
        Description = "Highly customizable Wayland bar";
        Documentation = "https://github.com/Alexays/Waybar/wiki";
        PartOf = [ cfg.sessionTarget ];
        After = [ cfg.sessionTarget ];
      };
      Service = {
        Type = "simple";
        ExecStart =
          "${pkgs.waybar}/bin/waybar -c %h/.config/waybar/config.json -s %h/.config/waybar/style.css";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
      Install = { WantedBy = [ cfg.sessionTarget ]; };
    };
  });
}
