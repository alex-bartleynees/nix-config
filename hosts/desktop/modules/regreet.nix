{ config, lib, pkgs, background, ... }: {
  services.greetd = { enable = true; };

  programs.regreet = {
    enable = true;
    cageArgs = [ "-m" "last" ];
  };
}
