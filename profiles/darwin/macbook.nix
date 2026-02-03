{ pkgs, self, users, ... }: {
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
      options = "--delete-older-than 7d";
    };
  };

  environment.systemPackages = with pkgs; [ vim git ];
  environment.shells = [ pkgs.zsh ];

  system.configurationRevision = self.rev or self.dirtyRev or null;

  system.stateVersion = 5;

  # Configure all users
  users.users = builtins.listToAttrs (map (user: {
    name = user.username;
    value = {
      # workaround for https://github.com/nix-community/home-manager/issues/4026
      home = user.homeDirectory;
      shell = pkgs.zsh;
    };
  }) users);

  services.tailscale.enable = true;

  nixpkgs.hostPlatform = "aarch64-darwin";

  networking.hostName = "macbook";
}
