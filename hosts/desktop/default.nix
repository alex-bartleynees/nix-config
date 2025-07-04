{ inputs, ... }:
let
  inherit (inputs) nixpkgs;
  system = builtins.currentSystem;
  pkgs-cosmic = import inputs.cosmic-nixpkgs {
    system = "x86_64-linux";
    config.allowUnfree = true;
  };
  shared = import ../../shared/nixos-default.nix {
    inherit inputs;
    theme = "catppuccin-mocha";
  };
in nixpkgs.lib.nixosSystem {
  specialArgs = {
    inherit inputs;
    pkgs-cosmic = pkgs-cosmic;
    background = import ../../shared/background.nix { inherit inputs; };
  };
  modules = shared.getImports {
    additionalImports =
      [ ./modules/regreet.nix ./specialisations ./specialisations/hypr.nix ];
  };
}
