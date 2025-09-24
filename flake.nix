{
  description = "NixOS configuration";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-cosmic.url = "github:lilyinstarlight/nixos-cosmic";
    cosmic-nixpkgs.follows = "nixos-cosmic/nixpkgs";

    mac-app-util = { url = "github:hraban/mac-app-util"; };

    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    dotfiles = {
      url = "github:alex-bartleynees/dotfiles";
      flake = false;
    };

    lazyvim = { url = "github:alex-bartleynees/nix-devenv?dir=lazyvim"; };

    neovim = { url = "github:alex-bartleynees/nix-devenv?dir=neovim"; };
  };

  outputs = inputs@{ self, nixpkgs, home-manager, nixos-wsl, nix-darwin
    , mac-app-util, stylix, lazyvim, neovim, nixos-cosmic, cosmic-nixpkgs
    , sops-nix, disko, nixos-hardware, ... }:
    let
      mkLinuxSystem = import ./shared/mk-linux-system.nix { inherit inputs; };
      linuxHosts = import ./hosts.nix { inherit inputs; };
    in {
      nixosConfigurations =
        nixpkgs.lib.mapAttrs (name: config: mkLinuxSystem config) linuxHosts;

      darwinConfigurations = {
        macbook = import ./hosts/macbook { inherit inputs; };
      };
    };
}
