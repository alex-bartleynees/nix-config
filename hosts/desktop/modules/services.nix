{ config, pkgs, ... }: {
  # Enable CIFS/SMB support
  boot.supportedFilesystems = [ "cifs" ];

  # Install CIFS utilities
  environment.systemPackages = with pkgs; [ cifs-utils ];

  # Reference external credentials file (not in git)
  # Create /etc/samba-credentials manually with:
  # username=your-actual-username
  # password=your-actual-password  
  # domain=WORKGROUP

  # Auto-mount Samba share
  fileSystems."/mnt/media" = {
    device = "//100.98.211.116/jellyfin-pool";
    fsType = "cifs";
    options = let
      automount_opts = "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s";

    in ["${automount_opts},credentials=/etc/samba-credentials,uid=1000,gid=1000,file_mode=0664,dir_mode=0775,forceuid,forcegid"];
  };

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

  # services.udev.extraRules = ''
  #   # Enable wake from USB devices
  #   ACTION=="add", SUBSYSTEM=="usb", DRIVER=="usb", ATTR{power/wakeup}="enabled"
  #
  #   # Enable wake from specific USB ports (XHCI controller)
  #   SUBSYSTEM=="pci", ATTRS{vendor}=="0x8086", ATTRS{device}=="0x8c31", ATTR{power/wakeup}="enabled"
  # '';

  services.udev.extraRules = ''
    # Rules for Oryx web flashing and live training
    KERNEL=="hidraw*", ATTRS{idVendor}=="16c0", MODE="0664", GROUP="plugdev"
    KERNEL=="hidraw*", ATTRS{idVendor}=="3297", MODE="0664", GROUP="plugdev"

    # Legacy rules for live training over webusb (Not needed for firmware v21+)
    # Rule for all ZSA keyboards
    SUBSYSTEM=="usb", ATTR{idVendor}=="3297", GROUP="plugdev"
    # Rule for the Moonlander
    SUBSYSTEM=="usb", ATTR{idVendor}=="3297", ATTR{idProduct}=="1969", GROUP="plugdev"
    # Rule for the Ergodox EZ
    SUBSYSTEM=="usb", ATTR{idVendor}=="feed", ATTR{idProduct}=="1307", GROUP="plugdev"
    # Rule for the Planck EZ
    SUBSYSTEM=="usb", ATTR{idVendor}=="feed", ATTR{idProduct}=="6060", GROUP="plugdev"

    # Wally Flashing rules for the Ergodox EZ
    ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789B]?", ENV{ID_MM_DEVICE_IGNORE}="1"
    ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789A]?", ENV{MTP_NO_PROBE}="1"
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789ABCD]?", MODE:="0666"
    KERNEL=="ttyACM*", ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789B]?", MODE:="0666"

    # Keymapp / Wally Flashing rules for the Moonlander and Planck EZ
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="0483", ATTRS{idProduct}=="df11", MODE:="0666", SYMLINK+="stm32_dfu"
    # Keymapp Flashing rules for the Voyager
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="3297", MODE:="0666", SYMLINK+="ignition_dfu"
  '';

  services.tailscale.enable = true;
  services.tailscale.useRoutingFeatures = "client";

  #Game-streaming
  services.sunshine = {
    enable = true;
    # Enable nvenc support
    package = with pkgs;
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
