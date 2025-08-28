{ inputs, ... }:
let
  inherit (inputs) nixpkgs;
  system = builtins.currentSystem;
  shared = import ../../shared/nixos-default.nix {
    inherit inputs;
    theme = import ../../core/themes/tokyo-night.nix { inherit inputs; };
  };
in nixpkgs.lib.nixosSystem {
  specialArgs = { inherit inputs; };
  modules = shared.getImports {
    additionalImports =
      [ ./nixos/configuration.nix ./modules ../../core/desktops/gnome.nix ];
  };
}
