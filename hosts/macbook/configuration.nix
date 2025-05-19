{ self, config, lib, nix-darwin, pkgs, ... }: {
  programs.zsh.enable = true;
  nixpkgs.config.allowUnfree = true;
  nix = {
    settings = { experimental-features = [ "nix-command" "flakes" ]; };
    optimise.automatic = true;
    gc = {
      automatic = true;
      interval = {
        Weekday = 0;
        Hour = 3;
        Minute = 15;
      };
      options = "--delete-older-than 30d";
    };
  };

  environment.systemPackages = with pkgs; [ vim git ];
  environment.shells = [ pkgs.zsh ];

  system.configurationRevision = self.rev or self.dirtyRev or null;

  system.stateVersion = 5;

  users.users.alexbartleynees = {
    # workaround for https://github.com/nix-community/home-manager/issues/4026
    home = "/Users/alexbartleynees";
    shell = pkgs.zsh;
  };

  services.tailscale.enable = true;

  nixpkgs.hostPlatform = "aarch64-darwin";

  networking.hostName = "macbook";
}
