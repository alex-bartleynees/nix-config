{ inputs, ... }:
let inherit (inputs) nixpkgs nixos-wsl;
in nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  modules = [
    nixos-wsl.nixosModules.wsl
    ./nixos/configuration.nix
    ../../core/modules
    ../../shared/locale.nix
    ../../shared/custom-options.nix
    ../../users/alexbn.nix
    inputs.stylix.nixosModules.stylix
    { nixpkgs.config.allowUnfree = true; }
  ] ++ (import ../../shared/home-manager.nix {
    inherit inputs;
    username = "alexbn";
    homeDirectory = "/home/alexbn";
    theme = "tokyo-night";
    extraModules = [ ../../home ];
  });
}
