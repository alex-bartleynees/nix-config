{ lib, hostName, stateVersion, systemProfiles ? null, ... }: {
  options.system = {
    isWsl = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable WSL (Windows Subsystem for Linux) support";
    };
  };

  config = lib.mkMerge [
    # Dynamic profile configuration
    (lib.mkIf (systemProfiles != null) {
      profiles = lib.genAttrs systemProfiles (profile: true);
    })

    # System wide settings 
    {
      # Programs
      programs.zsh.enable = true;
      programs.dconf.enable = true;

      # DBus
      services.dbus = {
        enable = true;
        implementation = "broker";
      };

      nix = {
        settings = {
          auto-optimise-store = true;
          experimental-features = [ "nix-command" "flakes" ];
          substituters =
            [ "https://install.determinate.systems" "https://niri.cachix.org" ];
          trusted-public-keys = [
            "cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM="
            "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
          ];
          # Determinate Nix features
          eval-cores = 0; # Use all available cores for parallel evaluation
        };
        gc = {
          automatic = true;
          dates = "weekly";
          options = "--delete-older-than 7d";
        };
      };

      # Networking
      networking.hostName = hostName;

      system.stateVersion = stateVersion;
    }
  ];
}
