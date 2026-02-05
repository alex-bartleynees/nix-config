{ config, lib, theme, pkgs, ... }:
let
  allUserPersistPaths = lib.flatten
    (lib.mapAttrsToList (username: userConfig: userConfig.persistPaths or [ ])
      config.myUsers);
  rootPaths = import ../shared/root-persistence.nix { };
in lib.mkIf config.profiles.linux-desktop {
  # Inherit base profile
  profiles.base = true;

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.consoleMode = "max";

  boot = {
    kernelPackages = pkgs.linuxKernel.packages.linux_zen;

    # Increase inotify watch limit for IDEs (IntelliJ, VSCode, etc.)
    kernel.sysctl = { "fs.inotify.max_user_watches" = 1048576; };
  };

  # Hardware
  hardware.graphics = { enable = true; };
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # Programs
  programs.nm-applet = { enable = true; };

  # Services
  services.dbus.packages = with pkgs; [ gnome-keyring xdg-desktop-portal ];
  services.blueman.enable = true;
  services.upower.enable = true;
  services.acpid.enable = true;
  services.xserver.xkb = {
    layout = "nz";
    variant = "";
  };
  services.udisks2.enable = true;
  services.gnome.gnome-keyring.enable = true;

  # Security
  security.pam.services.login.enableGnomeKeyring = true;
  security.polkit.enable = true;

  # Allow users in wheel group to switch specialisations without sudo
  security.sudo.extraRules = [{
    groups = [ "wheel" ];
    commands = [{
      command = "/nix/store/*/specialisation/*/bin/switch-to-configuration";
      options = [ "NOPASSWD" ];
    }];
  }];

  # Networking
  networking.nameservers = [ "8.8.8.8" "1.1.1.1" ];
  networking.networkmanager.enable = true;

  # Audio
  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  # Root user
  users.mutableUsers = false;
  users.users.root = {
    initialHashedPassword =
      "$6$n2D1ZBpbcavgoyMs$lwoQv71z3pGUStla4XV7jWGJnFEfU16aODX0F1JbhuUrvqn1JsjEQ7QMKB8qvItrmH5R0qEax/AIOAygpJdRW.";
    hashedPasswordFile = config.sops.secrets."passwords/root".path;
  };

  # Theming configuration
  stylixTheming = {
    enable = true;
    image = theme.wallpaper;
    base16Scheme = theme.base16Scheme;
  };

  # Common desktop services
  sambaClient.enable = true;
  silentBoot.enable = true;
  zswap.enable = true;
  snapshots.enable = true;

  # Impermanence configuration for BTRFS
  impermanence = {
    enable = true;
    subvolumes = {
      "@" = { mountpoint = "/"; };
      "@home" = { mountpoint = "/home"; };
    };
    persistPaths = rootPaths.rootPersistPaths ++ allUserPersistPaths;
    resetSubvolumes = [ ];
  };
}
