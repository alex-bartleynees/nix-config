{ inputs, ... }:
let
  inherit (inputs) nix-darwin;
  username = "alexbartleynees";
  homeDirectory = "/Users/alexbartleynees";
in nix-darwin.lib.darwinSystem {
  system = "aarch64-darwin";
  modules = [ ./configuration.nix { _module.args.self = inputs.self; } ]
    ++ (import ../../shared/darwin-home-manager.nix {
      inherit inputs username homeDirectory;
      extraModules =
        [ ../../home ../../home/modules/vscode ../../home/modules/mac ];
    });
}
