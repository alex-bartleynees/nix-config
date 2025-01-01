{ self, config, lib, nix-darwin, pkgs, ... }: {
  programs.zsh.enable = true;
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  environment.systemPackages = with pkgs; [ vim wget git openssl ];

  system.configurationRevision = self.rev or self.dirtyRev or null;

  system.stateVersion = 5;

  users.users.alexbartleynees = {
    # workaround for https://github.com/nix-community/home-manager/issues/4026
    home = "/Users/alexbartleynees";
    shell = pkgs.zsh;
  };

  nixpkgs.hostPlatform = "aarch64-darwin";
}
