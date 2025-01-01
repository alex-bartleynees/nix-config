{ self, nix-darwin, nixpkgs, ... }: {
  programs.zsh.enable = true;
  nixpkgs.config.allowUnfree = true;
  services.openssh.enable = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  environment.systemPackages = with pkgs; [ vim wget git openssl ];

  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    autoPrune.enable = true;
  };

  system.configurationRevision = self.rev or self.dirtyRev or null;

  system.stateVersion = "5";

  nixpkgs.hostPlatform = "aarch64-darwin";
}
