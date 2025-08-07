{ config, pkgs, ... }: {
  virtualisation.virtualbox.host.enable = true;
  virtualisation.virtualbox.host.enableExtensionPack = true;
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    autoPrune.enable = true;
  };

  # Enable kernel modules and VirtualBox service
  boot.kernelModules = [ "vboxdrv" "vboxnetadp" "vboxnetflt" ];

  # Add your user to vboxusers group
  users.extraGroups.vboxusers.members = [ "alexbn" ];
}
