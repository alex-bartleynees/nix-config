{ config, pkgs, lib, ... }:
let
  username = "alexbn";
  commonPersistPaths =
    import ../shared/common-persist-paths.nix { inherit username; };
in {
  users = lib.mkIf pkgs.stdenv.isLinux {
    users.${username} = {
      isNormalUser = true;
      shell = pkgs.zsh;
      description = username;
      extraGroups =
        [ "networkmanager" "wheel" "docker" "i2c" "plugdev" "video" "render" ];
      packages = with pkgs; [ ];
      initialHashedPassword =
        "$6$fj6v7DyFbiqBDSSi$3M6vGFcbI2rxhKwAU49FDhWeA6ZKZKMPRuTtWkZMkrECXko9goxJje94.drywOXZSV4Sv7GFecTX1c06qOxTV/";
      hashedPasswordFile = config.sops.secrets."passwords/alexbn".path;
    };
  };

  myUsers.${username} = {
    git = {
      userName = "Alex Bartley Nees";
      userEmail = "alexbartleynees@gmail.com";
      workEmail = "alexander.nees@valocityglobal.com";
    };
    persistPaths = commonPersistPaths;
  };

  home-manager.users.${username}.home.file = {
    ".ssh/id_ed25519.pub".text =
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFKxSGAbg6Dw8DqxiPGikz9ZoXDBI6YvV80L5B1NsQ72 alexbartleynees@gmail.com";
    ".ssh/id_work.pub".text =
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICiiLMs/3ZZ8CDseUprOV5OzFJovG9GcP96GBg3HlQj+ alexander.nees@valocityglobal.com";
  };
}

