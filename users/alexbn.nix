{ config, pkgs, ... }: {
  users.users.alexbn = {
    isNormalUser = true;
    shell = pkgs.zsh;
    description = "alexbn";
    extraGroups = [ "networkmanager" "wheel" "docker" "i2c" "plugdev" ];
    packages = with pkgs; [ ];
  };
}

