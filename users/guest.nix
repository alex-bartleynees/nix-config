{ config, pkgs, lib, ... }:
let
  username = "guest";
  persistPaths =
    import ../shared/common-persist-paths.nix { inherit username; };
in {
  users = lib.mkIf pkgs.stdenv.isLinux {
    users.${username} = {
      isNormalUser = true;
      shell = pkgs.zsh;
      description = username;
      extraGroups = [ "networkmanager" "video" "render" ];
      packages = with pkgs; [ ];
      initialHashedPassword =
        "$6$fj6v7DyFbiqBDSSi$3M6vGFcbI2rxhKwAU49FDhWeA6ZKZKMPRuTtWkZMkrECXko9goxJje94.drywOXZSV4Sv7GFecTX1c06qOxTV/";
      hashedPasswordFile = config.sops.secrets."passwords/${username}".path;
    };
  };

  myUsers.${username} = { persistPaths = persistPaths.commonPersistPaths; };
}

