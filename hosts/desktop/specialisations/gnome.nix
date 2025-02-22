{ config, pkgs, inputs, ... }: {
  imports = [
    ../../../shared/locale.nix
    ../../../users/alexbn.nix
    ../modules/boot.nix
    ../modules/hardware.nix
    ../modules/packages.nix
    ../modules/services.nix
    ../modules/virtualisation.nix
    ../modules/wayland.nix
    ../nixos/configuration.nix
    inputs.stylix.nixosModules.stylix
    ../modules/stylix.nix
  ] ++ (import ../../../shared/home-manager.nix {
    inherit inputs;
    username = "alexbn";
    homeDirectory = "/home/alexbn";
    extraModules = [ ../../../home ];
    theme = "catppuccin-mocha";
  });

  networking.hostName = "gnome";

  services.xserver = {
    enable = true;
    displayManager.gdm.enable = true;
    displayManager.gdm.wayland = true;
    desktopManager.gnome.enable = true;
  };

  services.gnome = {
    core-utilities.enable = true;
    gnome-keyring.enable = true;
  };

  programs.dconf.enable = true;

  environment.systemPackages = with pkgs; [
    gnome.gnome-tweaks
    gnome.dconf-editor
    gnome.gnome-shell-extensions
  ];

  services.upower.enable = true;
  services.accounts-daemon.enable = true;

  environment.sessionVariables = { NIXOS_OZONE_WL = "1"; };

  system.nixos.tags = [ "gnome" ];

  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-gnome
    ];
  };

}
