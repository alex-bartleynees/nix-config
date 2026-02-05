# homeModule: true
{ config, lib, ... }:
let cfg = config.dunst;
in {
  options.dunst = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Dunst notification daemon configuration.";
    };

    colors = lib.mkOption {
      type = lib.types.submodule {
        options = {
          background = lib.mkOption {
            type = lib.types.str;
            default = "#2e3440";
            description = "Background color for notifications.";
          };
          foreground = lib.mkOption {
            type = lib.types.str;
            default = "#d8dee9";
            description = "Text color for notifications.";
          };
          frameColor = lib.mkOption {
            type = lib.types.str;
            default = "#5e81ac";
            description = "Frame color for notifications.";
          };
          criticalFrameColor = lib.mkOption {
            type = lib.types.str;
            default = "#bf616a";
            description = "Frame color for critical notifications.";
          };
        };
      };
      default = { };
      description = "Color configuration for dunst notifications.";
    };

    extraSettings = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Extra settings for dunst configuration.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.dunst = {
      enable = true;
      settings = lib.recursiveUpdate {
        global = {
          frame_color = lib.mkForce cfg.colors.frameColor;
          separator_color = lib.mkForce "frame";
        };
        urgency_low = {
          background = lib.mkForce cfg.colors.background;
          foreground = lib.mkForce cfg.colors.foreground;
          frame_color = lib.mkForce cfg.colors.frameColor;
        };
        urgency_normal = {
          background = lib.mkForce cfg.colors.background;
          foreground = lib.mkForce cfg.colors.foreground;
          frame_color = lib.mkForce cfg.colors.frameColor;
        };
        urgency_critical = {
          background = lib.mkForce cfg.colors.background;
          foreground = lib.mkForce cfg.colors.foreground;
          frame_color = lib.mkForce cfg.colors.criticalFrameColor;
        };
      } cfg.extraSettings;
    };
  };
}
