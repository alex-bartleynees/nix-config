{ config, pkgs, lib, ... }: {
  users = lib.mkIf pkgs.stdenv.isLinux {
    users.alexbn = {
      isNormalUser = true;
      shell = pkgs.zsh;
      description = "alexbn";
      extraGroups =
        [ "networkmanager" "wheel" "docker" "i2c" "plugdev" "video" "render" ];
      packages = with pkgs; [ ];
      initialHashedPassword =
        "$6$fj6v7DyFbiqBDSSi$3M6vGFcbI2rxhKwAU49FDhWeA6ZKZKMPRuTtWkZMkrECXko9goxJje94.drywOXZSV4Sv7GFecTX1c06qOxTV/";
      hashedPasswordFile = config.sops.secrets."passwords/alexbn".path;
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

