{ inputs, ... }:
let
  inherit (inputs) nixpkgs;
  system = builtins.currentSystem;
  pkgs = import nixpkgs {
    system = "x86_64-linux";
    config = { allowUnfree = true; };
  };
  theme = import ../../core/themes/tokyo-night.nix { inherit inputs pkgs; };
  shared = import ../../shared/nixos-default.nix { inherit inputs theme; desktop = "gnome"; };
in nixpkgs.lib.nixosSystem {
  specialArgs = { inherit inputs; };
  modules = shared.getImports {
    additionalImports = [
      ./nixos/configuration.nix
      ./modules
      ../../core/desktops/gnome.nix
      { _module.args.theme = theme; }
    ];
  };
}
