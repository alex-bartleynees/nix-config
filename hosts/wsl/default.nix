{ inputs, ... }:
let
  inherit (inputs) nixpkgs nixos-wsl;
  pkgs = import nixpkgs {
    system = "x86_64-linux";
    config = { allowUnfree = true; };
  };
  theme = import ../../core/themes/tokyo-night.nix { inherit inputs pkgs; };
  nixosDefaults = import ../../shared/nixos-default.nix {
    inherit inputs theme;
    username = "alexbn";
    homeDirectory = "/home/alexbn";
    desktop = "wsl";
  };
in nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  modules = nixosDefaults.getImports {
    additionalImports = [
      nixos-wsl.nixosModules.wsl
      ./nixos/configuration.nix
      { _module.args.theme = theme; }
    ];
  };
}
