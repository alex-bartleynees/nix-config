{ inputs, ... }:
let
  inherit (inputs) nix-darwin;
  username = "alexbn";
  homeDirectory = "/Users/alexbn";
in nix-darwin.lib.darwinSystem {
  modules = [ ./configuration.nix ../../users/alexbn.nix ../../shared/custom-options.nix { _module.args.self = inputs.self; } ]
    ++ (import ../../shared/darwin-home-manager.nix {
      inherit inputs username homeDirectory;
      extraModules = [ ../../home ];
    });
}
