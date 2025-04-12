{ self, config, lib, nix-darwin, pkgs, ... }: {
  programs.zsh.enable = true;
  nixpkgs.config.allowUnfree = true;
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
    };
    gc = {
      automatic = true;
      dates = "weekly";
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
