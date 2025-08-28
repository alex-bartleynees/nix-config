{ inputs, ... }:
let
  inherit (inputs) nixpkgs;
  system = builtins.currentSystem;
  pkgs = import nixpkgs {
    system = "x86_64-linux";
    config = { allowUnfree = true; };
  };
  pkgs-cosmic = import inputs.cosmic-nixpkgs {
    system = "x86_64-linux";
    config.allowUnfree = true;
  };
  theme = import ../../core/themes/tokyo-night.nix { inherit inputs pkgs; };
  themes = import ../../core/themes {
    inherit inputs;
    lib = nixpkgs.lib;
  };
  shared = import ../../shared/nixos-default.nix { inherit inputs theme; };
in nixpkgs.lib.nixosSystem {
  specialArgs = {
    inherit inputs theme;
    pkgs-cosmic = pkgs-cosmic;
  };
  modules = shared.getImports {
    additionalImports = [
      ./modules
      ./nixos/configuration.nix
      ./specialisations
      ../../core/desktops/hypr.nix
      # Auto-generated theme specializations
      (themes.mkThemeSpecialisations {
        baseConfig = shared.getImports {
          additionalImports = [ ./modules ./nixos/configuration.nix ];
        };
        desktop = "hypr";
      })
    ];
  };
}
