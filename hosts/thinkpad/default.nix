{ inputs, ... }:
let
  inherit (inputs) nixpkgs;
  system = builtins.currentSystem;
  pkgs = import nixpkgs {
    system = "x86_64-linux";
    config = { allowUnfree = true; };
  };
  theme = import ../../core/themes/tokyo-night.nix { inherit inputs pkgs; };
  themes = import ../../core/themes {
    inherit inputs;
    lib = nixpkgs.lib;
  };
  shared = import ../../shared/nixos-default.nix { inherit inputs theme; };
in nixpkgs.lib.nixosSystem {
  specialArgs = { inherit inputs; };
  modules = shared.getImports {
    additionalImports = [
      ./modules
      ./nixos/configuration.nix
      ../../core/desktops/hypr.nix
      inputs.nixos-hardware.nixosModules.lenovo-thinkpad-t490
      {
        _module.args.theme = theme;
      }
      # Auto-generated theme specializations
      (themes.mkThemeSpecialisations {
        baseImports = [ ./modules ./nixos/configuration.nix ];
        desktop = "hypr";
      })
    ];
  };
}
