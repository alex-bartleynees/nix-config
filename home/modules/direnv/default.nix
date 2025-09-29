{ ... }: {
  programs.direnv = {
    enable = true;
    enableZshIntegration = true; # If you're using zsh
    nix-direnv.enable = true; # Better caching
  };
}
