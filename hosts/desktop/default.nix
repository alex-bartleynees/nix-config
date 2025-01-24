{ inputs, ... }:
let inherit (inputs) nixpkgs;
in nixpkgs.lib.nixosSystem {
  specialArgs = {
    background = import ../../shared/background.nix { inherit inputs; };
  };
  modules = [
    ./nixos/configuration.nix
    ./modules
    ../../shared/locale.nix
    ../../users/alexbn.nix
  ] ++ (import ../../shared/home-manager.nix {
    inherit inputs;
    username = "alexbn";
    homeDirectory = "/home/alexbn";
    extraModules = [ ../../home ];
    theme = "catppuccin-mocha";
  });
}
