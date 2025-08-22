{ config, pkgs, lib, ... }: {
  users.users = lib.mkIf pkgs.stdenv.isLinux {
    alexbn = {
      isNormalUser = true;
      shell = pkgs.zsh;
      description = "alexbn";
      extraGroups =
        [ "networkmanager" "wheel" "docker" "i2c" "plugdev" "video" "render" ];
      packages = with pkgs; [ ];
      initialPassword = "temppassword";
    };
  };

  myUsers.alexbn.git = {
    userName = "Alex Bartley Nees";
    userEmail = "alexbartleynees@gmail.com";
    workEmail = "alexander.nees@valocityglobal.com";
  };

  home-manager.users.alexbn.home.file = {
    ".ssh/id_ed25519.pub".text =
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFKxSGAbg6Dw8DqxiPGikz9ZoXDBI6YvV80L5B1NsQ72 alexbartleynees@gmail.com";
    ".ssh/id_work.pub".text =
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICiiLMs/3ZZ8CDseUprOV5OzFJovG9GcP96GBg3HlQj+ alexander.nees@valocityglobal.com";
  };
}

