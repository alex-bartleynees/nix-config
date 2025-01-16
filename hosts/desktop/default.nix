{ inputs, ... }:
let inherit (inputs) nixpkgs;
in nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
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
    extraModules =
      [ ../../home ../../home/modules/desktop ../../home/modules/linux ];
    theme = "catppuccin-mocha";
  });
}
