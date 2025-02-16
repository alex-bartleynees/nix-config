{ inputs, ... }:
let
  inherit (inputs) nixpkgs;
  system = builtins.currentSystem;
  nixpkgs-unstable = import inputs.nixpkgs-unstable {
    system = "x86_64-linux";
    config.allowUnfree = true;
  };
in nixpkgs.lib.nixosSystem {
  specialArgs = {
    nixpkgs-unstable = nixpkgs-unstable;
    background = import ../../shared/background.nix { inherit inputs; };
  };
  modules = [
    ./nixos/configuration.nix
    ./modules
    ../../shared/locale.nix
    ../../users/alexbn.nix
    inputs.stylix.nixosModules.stylix
  ] ++ (import ../../shared/home-manager.nix {
    inherit inputs;
    username = "alexbn";
    homeDirectory = "/home/alexbn";
    extraModules = [ ../../home ];
    theme = "catppuccin-mocha";
  });
}
