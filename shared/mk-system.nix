{ inputs }:
({ system ? "x86_64-linux", stateVersion ? "25.05", desktop ? "hyprland", users
  , themeName ? "tokyo-night", hostName, enableThemeSpecialisations ? false
  , enableDesktopSpecialisations ? false, desktopSpecialisations ? [ ]
  , additionalModules ? [ ], additionalSpecialArgs ? { }
  , additionalUserProfiles ? { }, isDarwin ? false }:
  let
    inherit (inputs) nixpkgs nix-darwin;

    # Constants
    allowUnfreeConfig = { allowUnfree = true; };

    # Package sets
    pkgs = import nixpkgs {
      inherit system;
      config = allowUnfreeConfig;
    };

    # Hardware configuration
    hardwareConfig = if !isDarwin && builtins.pathExists
    (../hardware + "/${hostName}-hardware-configuration.nix") then
      [ ../hardware/${hostName}-hardware-configuration.nix ]
    else
      [ ];

    # Disk configuration
    diskConfig = if !isDarwin && builtins.pathExists
    (../disk-config + "/${hostName}-disk-config.nix") then
      [ ../disk-config/${hostName}-disk-config.nix ]
    else
      [ ];

    # Host configuration
    hostConfig = if builtins.pathExists (../hosts + "/${hostName}.nix") then
      [ ../hosts/${hostName}.nix ]
    else
      [ ];

    baseImports = hostConfig ++ hardwareConfig ++ diskConfig;

    # Theme setup
    theme = import ../core/themes/${themeName}.nix { inherit inputs pkgs; };
    themes = if !isDarwin then
      import ../core/themes {
        inherit inputs users;
        lib = nixpkgs.lib;
      }
    else
      null;
    themeSpecialisations = if enableThemeSpecialisations && !isDarwin then
      [
        (themes.mkThemeSpecialisations {
          baseImports = baseImports;
          inherit desktop;
        })
      ]
    else
      [ ];

    # Desktop specialisations 
    mkDesktopSpecialisations = if !isDarwin then
      import ./mk-desktop-specialisations.nix {
        inherit inputs;
        lib = nixpkgs.lib;
      }
    else
      null;
    desktopSpecialisationModules =
      if enableDesktopSpecialisations && !isDarwin then
        [
          (mkDesktopSpecialisations {
            baseImports = baseImports;
            inherit theme users;
            desktops = desktopSpecialisations;
          })
        ]
      else
        [ ];

    # Shared configuration
    shared = import ../shared/nixos-default.nix {
      inherit inputs theme desktop users additionalUserProfiles isDarwin;
      lib = nixpkgs.lib;
    };

    # Desktop module
    desktopConfig = if !isDarwin
    && builtins.pathExists (../core/desktops + "/${desktop}.nix") then
      [ ../core/desktops/${desktop}.nix ]
    else
      [ ];

    # Base modules for the system
    baseModules = shared.getImports {
      additionalImports = baseImports ++ desktopConfig ++ additionalModules
        ++ [{ _module.args.theme = theme; }] ++ themeSpecialisations
        ++ desktopSpecialisationModules;
    };

    # Common special args
    commonSpecialArgs = {
      inherit inputs users desktop hostName stateVersion;
      self = inputs.self;
    } // additionalSpecialArgs;

  in if isDarwin then
    nix-darwin.lib.darwinSystem {
      inherit system;
      specialArgs = commonSpecialArgs;
      modules = baseModules;
    }
  else
    nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = commonSpecialArgs;
      modules = baseModules;
    })

