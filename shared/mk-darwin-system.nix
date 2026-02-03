{ inputs }:
({ system ? "aarch64-darwin", stateVersion ? "25.05", systemProfiles, desktop
  , users, themeName ? "tokyo-night", hostName, additionalUserProfiles ? { }, }:
  let
    inherit (inputs) nixpkgs nix-darwin;

    # Constants
    allowUnfreeConfig = { allowUnfree = true; };

    # Package sets
    pkgs = import nixpkgs {
      inherit system;
      config = allowUnfreeConfig;
    };

    # Theme setup
    theme = import ../themes/${themeName}.nix { inherit inputs pkgs; };

    # Shared configuration
    shared = import ../shared/darwin-default.nix {
      inherit inputs users theme desktop hostName additionalUserProfiles;
    };

    # Base modules for the system
    baseModules = shared.getImports { };

    # Common special args
    commonSpecialArgs = {
      inherit inputs users desktop hostName stateVersion systemProfiles;
      self = inputs.self;
    };
  in nix-darwin.lib.darwinSystem {
    inherit system;
    specialArgs = commonSpecialArgs;
    modules = baseModules;
  })
