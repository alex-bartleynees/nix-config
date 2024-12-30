{ config, pkgs, ... }: {
  users.users.alexbn = {
    isNormalUser = true;
    shell = pkgs.zsh;
    description = "alexbn";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    packages = with pkgs; [ ];
  };
}

