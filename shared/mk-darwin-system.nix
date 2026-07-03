{ inputs }:
({ system ? "aarch64-darwin", stateVersion ? "25.05", systemProfiles, desktop
  , users, themeName ? "tokyo-night", hostName, additionalUserProfiles ? { }
  , isDarwin ? true, }:
  let
    inherit (inputs) nixpkgs nix-darwin;
    self = inputs.self;
    paths = import "${self}/paths.nix" self;

    # Constants
    allowUnfreeConfig = { allowUnfree = true; };

    # Package sets
    pkgs = import nixpkgs {
      inherit system;
      config = allowUnfreeConfig;
    };

    # Theme setup
    theme = import "${paths.themes}/${themeName}.nix" { inherit inputs pkgs; };

    # Shared configuration
    shared = import ./darwin-default.nix {
      inherit inputs self users theme desktop hostName additionalUserProfiles;
    };

    # Base modules for the system
    baseModules = shared.getImports { };

    # Common special args
    commonSpecialArgs = {
      inherit inputs self users desktop hostName stateVersion systemProfiles;
    };
  in nix-darwin.lib.darwinSystem {
    inherit system pkgs;
    specialArgs = commonSpecialArgs;
    modules = baseModules;
  })
