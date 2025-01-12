{ config, lib, pkgs, background, ... }:

let
  gtkgreetStyle = pkgs.writeText "gtkgreet.css" ''
    window {
      background-image: url("/etc/greetd/background.png");
      background-size: cover;
      background-position: center;
    }

    box#body {
       background-color: rgba(50, 50, 50, 0.5);
       border-radius: 10px;
       padding: 50px;
    }  '';

  swayConfig = pkgs.writeText "greetd-sway-config" ''
    xwayland disable
    output DP-4 enable
    output DP-6 disable

    # Disable unnecessary IPC features
    exec_always "systemctl --user import-environment DISPLAY WAYLAND_DISPLAY SWAYSOCK XDG_CURRENT_DESKTOP"
    exec_always "dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY SWAYSOCK XDG_CURRENT_DESKTOP"

    # `-l` activates layer-shell mode. Notice that `swaymsg exit` will run after gtkgreet.
    exec ${pkgs.greetd.gtkgreet}/bin/gtkgreet -l -s ${gtkgreetStyle}; swaymsg exit'"
    bindsym Mod1+shift+e exec swaynag \
      -t warning \
      -m 'What do you want to do?' \
      -b 'Poweroff' 'systemctl poweroff' \
      -b 'Reboot' 'systemctl reboot'
  '';

  sway-run = pkgs.writeTextFile {
    name = "sway-run";
    destination = "/bin/sway-run";
    executable = true;
    text = ''
      #!${pkgs.zsh}/bin/zsh
      # # Session
      # export XDG_SESSION_TYPE=wayland
      # export XDG_SESSION_DESKTOP=sway
      # export XDG_CURRENT_DESKTOP=sway
      # Wayland specific
      # export MOZ_ENABLE_WAYLAND=1
      # export QT_QPA_PLATFORM=wayland
      # export SDL_VIDEODRIVER=wayland
      # export _JAVA_AWT_WM_NONREPARENTING=1
      # export GTK_USE_PORTAL=0

      # NVIDIA specific optimizations
      # export WLR_NO_HARDWARE_CURSORS=1
      # export NIXOS_OZONE_WL=1
      # export WLR_RENDERER=vulkan
      # export __GLX_VENDOR_LIBRARY_NAME=nvidia
      # export GBM_BACKEND=nvidia-drm

      # Source zsh specific files
      [ -f "$HOME/.zshenv" ] && . "$HOME/.zshenv"
      [ -f "$HOME/.zshrc" ] && . "$HOME/.zshrc"
      exec sway --unsupported-gpu "$@"
    '';
  };
in {
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command =
          "${pkgs.sway}/bin/sway --config ${swayConfig} --unsupported-gpu";
      };
    };
  };

  environment.etc = {
    "greetd/background.png".source = background.wallpaper;
    "greetd/environments".text = ''
      ${sway-run}/bin/sway-run
    '';
  };
}
