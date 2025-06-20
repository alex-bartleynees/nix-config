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

    nixpkgs.follows = "nixos-cosmic/nixpkgs";
    nixos-cosmic.url = "github:lilyinstarlight/nixos-cosmic";
    cosmic-nixpkgs.follows = "nixos-cosmic/nixpkgs";

    mac-app-util = { url = "github:hraban/mac-app-util"; };

    stylix = {
      url = "github:danth/stylix";
      inputs.home-manager.follows = "home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dotfiles = {
      url = "github:alex-bartleynees/dotfiles";
      flake = false;
    };

    lazyvim = { url = "github:alex-bartleynees/nix-devenv?dir=lazyvim"; };

    neovim = { url = "github:alex-bartleynees/nix-devenv?dir=neovim"; };
  };

  outputs = inputs@{ self, nixpkgs, home-manager, nixos-wsl, nix-darwin
    , mac-app-util, stylix, lazyvim, neovim, nixos-cosmic, cosmic-nixpkgs
    , sops-nix, ... }: {
      nixosConfigurations = {
        nixos = import ./hosts/desktop { inherit inputs; };
        wsl = import ./hosts/wsl { inherit inputs; };
      };

      darwinConfigurations = {
        macbook = import ./hosts/macbook { inherit inputs; };
      };
    };
}
