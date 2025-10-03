{ config, lib, pkgs, ... }:
let cfg = config.silentBoot;
in {
  options.silentBoot.enable = lib.mkEnableOption "Enable silent boot";
  config = lib.mkIf cfg.enable {
    boot = {
      consoleLogLevel = 3;
      initrd.verbose = false;
      initrd.systemd.enable = true;
      kernelParams = [
        "quiet"
        "splash"
        "intremap=on"
        "boot.shell_on_fail"
        "udev.log_priority=3"
        "rd.systemd.show_status=auto"
      ];

      plymouth.enable = true;
      plymouth.font =
        "${pkgs.nerd-fonts.jetbrains-mono}/share/fonts/truetype/NerdFonts/JetBrainsMono/JetBrainsMonoNerdFont-Regular.ttf";
      plymouth.logo =
        "${pkgs.nixos-icons}/share/icons/hicolor/128x128/apps/nix-snowflake.png";
    };
  };
}
