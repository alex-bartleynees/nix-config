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
          substituters = [ "https://niri.cachix.org" ];
          trusted-public-keys = [
            "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
          ];
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
