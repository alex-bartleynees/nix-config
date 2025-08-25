{ inputs, ... }:
let
  inherit (inputs) nixpkgs;
  system = builtins.currentSystem;
  shared = import ../../shared/nixos-default.nix {
    inherit inputs;
    theme = "tokyo-night";
  };
in nixpkgs.lib.nixosSystem {
  specialArgs = {
    inherit inputs;
    background = import ../../shared/background.nix { inherit inputs; };
  };
  modules = shared.getImports {
    additionalImports =
      [ ./nixos/configuration.nix ./modules ../../core/desktops/gnome.nix ];
    };
  }
