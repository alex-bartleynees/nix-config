{ config, pkgs, nixpkgs-unstable, ... }: {
  services.xserver.videoDrivers = [ "nvidia" ];
  services.dbus.enable = true;
  services.dbus.packages = with pkgs; [
    pkgs.gnome-keyring
    pkgs.xdg-desktop-portal
  ];
  services.blueman.enable = true;
  services.upower.enable = true;
  services.acpid.enable = true;
  services.xserver.xkb = {
    layout = "nz";
    variant = "";
  };
  services.udisks2.enable = true;

  services.gnome.gnome-keyring.enable = true;

  services.udev.extraRules = ''
    # Enable wake from USB devices
    ACTION=="add", SUBSYSTEM=="usb", DRIVER=="usb", ATTR{power/wakeup}="enabled"

    # Enable wake from specific USB ports (XHCI controller)
    SUBSYSTEM=="pci", ATTRS{vendor}=="0x8086", ATTRS{device}=="0x8c31", ATTR{power/wakeup}="enabled"
  '';

  services.tailscale.enable = true;
  services.tailscale.useRoutingFeatures = "client";

  # Game-streaming
  services.sunshine = {
    enable = true;
    # Enable nvenc support
    package = with nixpkgs-unstable;
      (sunshine.override {
        cudaSupport = true;
        cudaPackages = cudaPackages;
      }).overrideAttrs (old: {
        nativeBuildInputs = old.nativeBuildInputs
          ++ [ cudaPackages.cuda_nvcc (lib.getDev cudaPackages.cuda_cudart) ];
        cmakeFlags = old.cmakeFlags
          ++ [ "-DCMAKE_CUDA_COMPILER=${(lib.getExe cudaPackages.cuda_nvcc)}" ];
      });
    openFirewall = true;
    capSysAdmin = true;
  };
}
