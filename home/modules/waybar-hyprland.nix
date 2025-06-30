{ pkgs, config, lib, theme, inputs, ... }: {
  programs.waybar = {
    enable = true;
    systemd.enable = true;

    settings = {
      mainBar = {
        layer = "bottom";
        position = "top";
        margin-bottom = 0;
        modules-left = [ "hyprland/workspaces" "hyprland/window" ];
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
          "custom/power"
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
          persistent_workspaces = {
            "1" = [];
            "2" = [];
            "3" = [];
            "4" = [];
            "5" = [];
          };
          on-click = "activate";
          on-scroll-up = "hyprctl dispatch workspace e+1";
          on-scroll-down = "hyprctl dispatch workspace e-1";
        };

        "hyprland/window" = { 
          max-length = 50;
          separate-outputs = true;
          rewrite = {
            "(.*) — Mozilla Firefox" = "🌎 $1";
            "(.*) - Visual Studio Code" = "󰨞 $1";
            "(.*) - vim" = " $1";
            "(.*) - nvim" = " $1";
          };
        };

        pulseaudio = {
          format = "{icon} {volume}%";
          format-bluetooth = "{icon}  {volume}%";
          format-muted = "󰝟 Muted";
          format-icons = {
            headphones = "";
            default = [ "" "" ];
          };
          scroll-step = 5;
        };

        memory = {
          interval = 5;
          format = "󰍛 {percentage}%";
          tooltip-format = "Memory: {used:0.1f}G/{total:0.1f}G ({percentage}%)\nSwap: {swapUsed:0.1f}G/{swapTotal:0.1f}G";
          on-click = "ghostty -e btop";
        };

        cpu = {
          interval = 2;
          format = "󰻠 {usage}%";
          tooltip-format = "CPU Usage: {usage}%\nLoad: {load}";
          on-click = "ghostty -e btop";
        };

        disk = {
          interval = 30;
          format = "  {percentage_used}%";
        };

        backlight = {
          device = "intel_backlight";
          format = "{percent}% {icon}";
          format-icons = [ "" "" ];
          on-scroll-up = "brightnessctl set 5%+";
          on-scroll-down = "brightnessctl set 5%-";
          tooltip-format = "Brightness: {percent}%";
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

        clock = {
          format = "{:%H:%M}";
          format-alt = "{:%A, %B %d, %Y (%R)}";
          tooltip-format = "<tt><small>{calendar}</small></tt>";
          calendar = {
            mode = "year";
            mode-mon-col = 3;
            weeks-pos = "right";
            on-scroll = 1;
            on-click-right = "mode";
            format = {
              months = "<span color='#ffead3'><b>{}</b></span>";
              days = "<span color='#ecc6d9'><b>{}</b></span>";
              weeks = "<span color='#99ffdd'><b>W{}</b></span>";
              weekdays = "<span color='#ffcc66'><b>{}</b></span>";
              today = "<span color='#ff6699'><b><u>{}</u></b></span>";
            };
          };
          actions = {
            on-click-right = "mode";
            on-click-forward = "tz_up";
            on-click-backward = "tz_down";
            on-scroll-up = "shift_up";
            on-scroll-down = "shift_down";
          };
        };

        tray = { spacing = 10; };

        "custom/weather" = {
          format = "{} °";
          tooltip = true;
          interval = 300;
          exec = "wttr.in/Cologne?0&T&Q&format=1";
          return-type = "json";
          on-click = "xdg-open https://wttr.in/Cologne";
        };

        "custom/separator" = {
          format = "|";
          interval = "once";
          tooltip = false;
        };

        "custom/power" = {
          format = "⏻";
          tooltip = false;
          on-click = "exec $HOME/.config/rofi/scripts/powermenu_t1";
        };
      };
    };

    style = ''
        * {
          font-family: "JetBrainsMono Nerd Font", "Font Awesome 6 Free", sans-serif;
          border: none;
          border-radius: 0;
          min-height: 0;
          font-size: 13px;
        }

        window#waybar {
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
          padding: 6px 20px;
          margin: 6px 3px;
          border-radius: 4px;
          background-color: #1e2030;
          color: #cdd6f4;
        }

      #workspaces button.active {
          color: #cdd6f4;
        }

        #workspaces button:hover {
          box-shadow: inherit;
          text-shadow: inherit;
          color: #181926;
          background-color: #b7bdf8;
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
          font-size: 13px;
          border-radius: 4px;
          margin: 6px 3px;
          padding: 6px 18px;
        	background-color: #1e2030
        }

        #memory {
          color: #fab387;
        }

        #cpu {
          color: #f9e2af;
        }

        #disk {
          color: #89dceb;
        }

        #battery {
          color: #f38ba8;
        }

        @keyframes blink {
          to {
            color: #f38ba8;
          }
        }

        #battery.warning,
        #battery.critical,
        #battery.urgent {
          color: #ff0048;
          animation-name: blink;
          animation-duration: 0.5s;
          animation-timing-function: linear;
          animation-iteration-count: infinite;
          animation-direction: alternate;
        }

        #battery.charging {
          color: #a6e3a1;
        }

        #backlight {
          color: #fab387;
        }

        #pulseaudio {
          color: #f9e2af;
        }

        #network {
          color: #94e2d5;
          padding-right: 17px;
        }

        #clock {
          color: #cba6f7;
        }

        #custom-power {
        color: #f2cdcd;
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
