# Game-streaming
{ config, lib, pkgs, ... }:
let cfg = config.gaming;
in {
  options.gaming = {
    # Enable gaming setup
    enable = lib.mkEnableOption "gaming setup";

    # Streaming options
    streaming = {
      enable = lib.mkEnableOption "game streaming with Sunshine";

      gpu = lib.mkOption {
        type = lib.types.enum [ "nvidia" "amd" "intel" ];
        default = "nvidia";
        description = "GPU to use for game streaming (nvidia, amd, intel)";
      };

      resolution = lib.mkOption {
        type = lib.types.str;
        default = "2560x1440@120";
        description = "Resolution for game streaming";
      };

      monitor = lib.mkOption {
        type = lib.types.int;
        default = 1;
        description = "Monitor to use for game streaming";
      };
    };

    # Moonlight options
    moonlight = { enable = lib.mkEnableOption "Moonlight game streaming"; };

    # Steam options
    steam = { enable = lib.mkEnableOption "Steam with custom launch service"; };
  };

  config = lib.mkMerge [
    # Base gaming config
    (lib.mkIf cfg.enable {
      programs.steam = {
        enable = true;
        extraCompatPackages = [ pkgs.proton-ge-bin ];
        remotePlay.openFirewall = true;
        dedicatedServer.openFirewall = true;
        localNetworkGameTransfers.openFirewall = true;
      };
    })

    # Game streaming config
    (lib.mkIf (cfg.enable && cfg.streaming.enable) {
      services.sunshine = {
        enable = true;
        package = pkgs.sunshine.override {
          cudaSupport = cfg.streaming.gpu == "nvidia";
        };
        openFirewall = true;
        capSysAdmin = true;
        settings = {
          encoder = if cfg.streaming.gpu == "nvidia" then
            "nvenc"
          else if cfg.streaming.gpu == "amd" then
            "vaapi"
          else
            "libx264";
          adapter_name =
            if cfg.streaming.gpu == "nvidia" then "/dev/dri/card2" else null;
          capture = "kms";
          output_name = cfg.streaming.monitor;
        };
        applications = {
          env = {
            PATH = "$(PATH):$(HOME)/.local/bin";
            CUDA_VISIBLE_DEVICES = "0";
            NVIDIA_VISIBLE_DEVICES = "all";
            __NV_PRIME_RENDER_OFFLOAD = "1";
            __GLX_VENDOR_LIBRARY_NAME = "nvidia";
            DRM_DEVICE = "/dev/dri/card2";
            WAYLAND_DISPLAY = "wayland-1";
            XDG_SESSION_TYPE = "wayland";
            GBM_BACKEND = "nvidia-drm";
            WLR_NO_HARDWARE_CURSORS = "1";
          };
          apps = [
            {
              name = "1440p Desktop";
              prep-cmd = [{
                do =
                  "${pkgs.hyprland}/bin/hyprctl keyword monitor DP-6,2560x1440@120,0x0,1";
                undo =
                  "${pkgs.hyprland}/bin/hyprctl keyword monitor DP-6,2560x1440@164.96,0x0,1";
              }];
              exclude-global-prep-cmd = "false";
              auto-detach = "true";
            }
            {
              name = "Steam Big Picture";
              prep-cmd = [{
                do =
                  "${pkgs.hyprland}/bin/hyprctl keyword monitor DP-6,2560x1440@164.96,0x0,1";
                undo =
                  "${pkgs.hyprland}/bin/hyprctl keyword monitor DP-6,2560x1440@164.96,0x0,1";
              }];
              detached = [ "steam-run-url steam://open/bigpicture" ];
              exclude-global-prep-cmd = "false";
              auto-detach = "true";
              image-path = "steam.png";
            }
          ];
        };
      };

      systemd.user.services.sunshine.path = [
        (pkgs.writeShellApplication {
          name = "steam-run-url";
          text = ''
            echo "$1" > "/run/user/$(id --user)/steam-run-url.fifo"
          '';
          runtimeInputs = [ pkgs.coreutils ];
        })
      ];

      #Steam launch service (bypasses Sunshine security wrapper issues)
      systemd.user.services.steam-run-url-service = {
        enable = true;
        description = "Listen and starts steam games by id";
        wantedBy = [ "graphical-session.target" ];
        partOf = [ "graphical-session.target" ];
        wants = [ "graphical-session.target" ];
        after = [ "graphical-session.target" ];
        serviceConfig.Restart = "on-failure";
        script = toString
          (pkgs.writers.writePython3 "steam-run-url-service" { } ''
            import os
            from pathlib import Path
            import subprocess

            pipe_path = Path(f'/run/user/{os.getuid()}/steam-run-url.fifo')
            try:
                pipe_path.parent.mkdir(parents=True, exist_ok=True)
                pipe_path.unlink(missing_ok=True)
                os.mkfifo(pipe_path, 0o600)
                while True:
                    with pipe_path.open(encoding='utf-8') as pipe:
                        subprocess.Popen(['steam', pipe.read().strip()])
            finally:
                pipe_path.unlink(missing_ok=True)
          '');
        path = [ pkgs.steam ];
      };

      # Helper script to easily launch Steam
      environment.systemPackages = [
        (pkgs.writeShellApplication {
          name = "steam-run-url";
          text = ''
            echo "$1" > "/run/user/$(id --user)/steam-run-url.fifo"
          '';
          runtimeInputs = [ pkgs.coreutils ];
        })
      ];
    })

    # Moonlight config
    (lib.mkIf cfg.moonlight.enable {
      environment.systemPackages = [ pkgs.moonlight-qt ];
    })
  ];
}

