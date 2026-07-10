{ config, pkgs, lib, ... }:
let
  username = "netclaw";
  sshKey =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFKxSGAbg6Dw8DqxiPGikz9ZoXDBI6YvV80L5B1NsQ72 alexbartleynees@gmail.com";
in {
  users = lib.mkIf pkgs.stdenv.isLinux {
    users.${username} = {
      isNormalUser = true;
      uid = 1000;
      shell = pkgs.zsh;
      description = "netclaw agent service account";
      openssh.authorizedKeys.keys = [ sshKey ];
      extraGroups = [ "systemd-journal" ];
      linger = true;
      packages = with pkgs; [ ];
      initialHashedPassword =
        "$6$fj6v7DyFbiqBDSSi$3M6vGFcbI2rxhKwAU49FDhWeA6ZKZKMPRuTtWkZMkrECXko9goxJje94.drywOXZSV4Sv7GFecTX1c06qOxTV/";
    };
  };

  myUsers.${username} = {
    needsPasswordSecret = false;
    profiles = [ ];
  };
}
