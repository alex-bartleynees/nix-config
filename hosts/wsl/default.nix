{ inputs, ... }:
let
  inherit (inputs) nixpkgs nixos-wsl;
  nixosDefaults = import ../../shared/nixos-default.nix {
    inherit inputs;
    username = "alexbn";
    homeDirectory = "/home/alexbn";
    theme = import ../../core/themes/tokyo-night.nix { inherit inputs; };
  };
in nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  modules = nixosDefaults.getImports {
    additionalImports = [
      nixos-wsl.nixosModules.wsl
      ./nixos/configuration.nix
      { nixpkgs.config.allowUnfree = true; }
    ];
  };
}
