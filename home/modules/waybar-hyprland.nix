{ pkgs, config, lib, theme, inputs, ... }: {
  programs.waybar = {
    enable = true;
    systemd.enable = true;

    settings = {
      mainBar = {
        layer = "bottom";
        position = "top";
        modules-left = [ "hyprland/workspaces" "hyprland/mode" ];
        modules-right = [
          "pulseaudio"
          "memory"
          "cpu"
          "disk"
          "battery"
          "backlight"
          "network"
          "clock"
          "tray"
        ];

        "hyprland/workspaces" = {
          format = "{icon}";
          format-icons = {
            "1" = "1";
            "2" = "2";
            "3" = "3";
            "4" = "4";
            "5" = "5";
            "6" = "6";
            "7" = "7";
            "8" = "8";
            "9" = "9";
            "10" = "10";
          };
        };

        "hyprland/window" = { max-length = 50; };

        pulseaudio = {
          format = "{icon} {volume:2}%";
          format-bluetooth = "{icon}  {volume}%";
          format-muted = "MUTE";
          format-icons = {
            headphones = "";
            default = [ "" "" ];
          };
          scroll-step = 5;
        };

        memory = {
          interval = 5;
          format = "Mem {}%";
        };

        cpu = {
          interval = 5;
          format = "CPU {usage:2}%";
        };

        disk = {
          interval = 30;
          format = "  {percentage_used}%";
        };

        backlight = {
          device = "intel_backlight";
          format = "{percent}% {icon}";
          format-icons = [ "" "" ];
          on-scroll-up = "";
          on-scroll-down = "";
        };

        network = {
          format-wifi = "{essid} ({signalStrength}%) ";
          format-ethernet = "{ifname}: {ipaddr}/{cidr} ";
          format-disconnected = "Disconnected ⚠";
          interval = 7;
        };

        battery = {
          format = "{capacity}% {icon}";
          format-icons = [ "" "" "" "" "" ];
        };

        clock = { format-alt = "{:%a, %d %b  %H:%M}"; };

        tray = { spacing = 10; };
      };
    };

    style = ''
        * {
          border: none;
          border-radius: 0;
          min-height: 0;
          font-size: 13px;
        }

        window#waybar {
          background-color: #181825;
          transition-property: background-color;
          transition-duration: 0.5s;
          opacity: 1;
        }

        window#waybar.hidden {
          opacity: 0.5;
        }

        #workspaces {
          background-color: transparent;
        }

        #workspaces button {
          all: initial;
          min-width: 0;
          box-shadow: inset 0 -3px transparent;
          padding: 6px 18px;
          margin: 6px 3px;
          border-radius: 4px;
          background-color: #1e1e2e;
          color: #cdd6f4;
        }

      #workspaces button.active {
          color: #cdd6f4;
        }

        #workspaces button:hover {
          box-shadow: inherit;
          text-shadow: inherit;
          color: #e1e2e7;
          background-color: #b4befe;
        }

        #workspaces button.urgent {
          background-color: #f38ba8;
        }

        #memory,
        #cpu,
        #disk,
        #custom-power,
        #battery,
        #backlight,
        #pulseaudio,
        #network,
        #clock,
        #tray {
          font-size: 12px;
          border-radius: 4px;
          margin: 6px 3px;
          padding: 6px 12px;
          background-color: #1e1e2e;
          color: #181825;
        }

        #memory {
          background-color: #fab387;
        }

        #cpu {
          background-color: #f9e2af;
        }

        #disk {
          background-color: #89dceb;
        }

        #battery {
          background-color: #f38ba8;
        }

        @keyframes blink {
          to {
            background-color: #f38ba8;
            color: #181825;
          }
        }

        #battery.warning,
        #battery.critical,
        #battery.urgent {
          background-color: #ff0048;
          color: #181825;
          animation-name: blink;
          animation-duration: 0.5s;
          animation-timing-function: linear;
          animation-iteration-count: infinite;
          animation-direction: alternate;
        }

        #battery.charging {
          background-color: #a6e3a1;
        }

        #backlight {
          background-color: #fab387;
        }

        #pulseaudio {
          background-color: #f9e2af;
        }

        #network {
          background-color: #94e2d5;
          padding-right: 17px;
        }

        #clock {
          font-family: JetBrainsMono Nerd Font;
          background-color: #cba6f7;
        }

        #custom-power {
          background-color: #f2cdcd;
        }

        #tray {
          background-color: #181825;
        }

        tooltip {
          border-radius: 8px;
          padding: 15px;
        }

        tooltip label {
          padding: 5px;
        }
    '';
  };
}
