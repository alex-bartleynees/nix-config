{ config, lib, username, ... }:
let cfg = config.virtualisation;
in {
  options.virtualisation = {
    enable = lib.mkEnableOption "Virtualisation support";

    user = lib.mkOption {
      type = lib.types.str;
      default = username;
      description = "User to add to the vboxusers group";
    };
  };

  config = lib.mkIf cfg.enable {
    # Virtualisation
    virtualisation.virtualbox.host.enable = true;
    virtualisation.virtualbox.host.enableExtensionPack = true;
    # Enable kernel modules and VirtualBox service
    boot.kernelModules = [ "vboxdrv" "vboxnetadp" "vboxnetflt" ];
    # Add your user to vboxusers group
    users.extraGroups.vboxusers.members = [ cfg.user ];
  };
}
