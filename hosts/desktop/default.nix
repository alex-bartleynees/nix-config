{ inputs, ... }:
let
  inherit (inputs) nixpkgs;
  system = builtins.currentSystem;
  nixpkgs-unstable = import inputs.nixpkgs-unstable {
    system = "x86_64-linux";
    config.allowUnfree = true;
  };
  pkgs-cosmic = import inputs.cosmic-nixpkgs {
    system = "x86_64-linux";
    config.allowUnfree = true;
  };
  shared = import ../../shared/nixos-default.nix { inherit inputs; };
in nixpkgs.lib.nixosSystem {
  specialArgs = {
    inherit inputs;
    nixpkgs-unstable = nixpkgs-unstable;
    pkgs-cosmic = pkgs-cosmic;
    background = import ../../shared/background.nix { inherit inputs; };
  };
  modules = shared.getImports {
    additionalImports =
      [ ./modules/regreet.nix ./modules/sway.nix ./specialisations ];
  };
}
