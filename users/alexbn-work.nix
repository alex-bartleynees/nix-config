{ config, pkgs, lib, ... }:
let
  username = "alexbn-work";
  commonHomePaths =
    import ./persistence/common-home-persistence.nix { inherit username; };
  developerPaths =
    import ./persistence/developer-persist-paths.nix { inherit username; };
  workPaths = import ./persistence/work-persistence.nix { inherit username; };
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
      hashedPasswordFile = config.sops.secrets."passwords/${username}".path;
    };
  };

  myUsers.${username} = {
    git = {
      userName = "Alex Bartley Nees";
      userEmail = "alexander.nees@valocityglobal.com";
      workEmail = "alexander.nees@valocityglobal.com";
    };
    persistPaths = commonHomePaths.commonHomePersistPaths
      ++ developerPaths.commonPersistPaths ++ workPaths.workPersistPaths;
    needsPasswordSecret = true;
    profiles = [ "developer" ];
  };

  home-manager.users.${username} = { config, ... }: {
    home.file = {
      ".ssh/id_ed25519.pub".text =
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFKxSGAbg6Dw8DqxiPGikz9ZoXDBI6YvV80L5B1NsQ72 alexbartleynees@gmail.com";
      ".ssh/id_work.pub".text =
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICiiLMs/3ZZ8CDseUprOV5OzFJovG9GcP96GBg3HlQj+ alexander.nees@valocityglobal.com";
    };

    home.sessionVariables = {
      ASPNETCORE_Kestrel__Certificates__Default__Path =
        "${config.home.homeDirectory}/.local-certs/gateway+6.p12";
      ASPNETCORE_Kestrel__Certificates__Default__Password = "changeit";
    };
  };
}

