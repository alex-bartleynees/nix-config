# Hardware

{ config, pkgs, ... }: {

	hardware.graphics = {
		enable = true;
	};

	hardware.bluetooth.enable = true;
 	hardware.bluetooth.powerOnBoot = true;

	hardware.nvidia = {
		modesetting.enable = true;
		powerManagement.enable = true;
		powerManagement.finegrained = false;
		open = true;
		nvidiaSettings = true;
		package = config.boot.kernelPackages.nvidiaPackages.stable;
	};
}
