{ inputs, ... }:
let inherit (inputs) nixpkgs nixos-wsl;
in nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  modules = [
    nixos-wsl.nixosModules.wsl
    ./nixos/configuration.nix
    ../../shared/locale.nix
    ../../users/alexbn.nix
    { nixpkgs.config.allowUnfree = true; }
  ] ++ (import ../../shared/home-manager.nix {
    inherit inputs;
    username = "alexbn";
    homeDirectory = "/home/alexbn";
    theme = "tokyo-night";
    extraModules = [ ../../home ];
  });
}
