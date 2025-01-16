{ inputs, ... }:
let inherit (inputs) nixpkgs;
in nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  modules = [
    nixos-wsl.nixosModules.wsl
    ./nixos/configuration.nix
    ../../shared/locale.nix
    ../../users/alexbn.nix
  ] ++ (import ../../shared/home-manager.nix {
    inherit inputs;
    username = "alexbn";
    homeDirectory = "/home/alexbn";
    extraModules = [ ./home ./home/modules/linux ];
  });
}
