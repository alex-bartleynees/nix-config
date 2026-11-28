{ lib, config, ... }: {
  options.system = {
    isWsl = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable WSL (Windows Subsystem for Linux) support";
    };
  };

  config = lib.mkMerge [
    # Dynamic profile configuration
    (lib.mkIf (config.myConfig.systemProfiles != [ ]) {
      profiles = lib.genAttrs config.myConfig.systemProfiles (_: true);
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
        };
        gc = {
          automatic = true;
          dates = "weekly";
          options = "--delete-older-than 7d";
        };
      };
    }
  ];
}
