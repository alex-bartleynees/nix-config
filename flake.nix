{
  description = "NixOS configuration";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mac-app-util = { url = "github:hraban/mac-app-util"; };

    dotfiles = {
      url = "github:alex-bartleynees/dotfiles";
      flake = false;
    };

    lazyvim = { url = "github:alex-bartleynees/nix-devenv?dir=lazyvim"; };

    neovim = { url = "github:alex-bartleynees/nix-devenv?dir=neovim"; };
  };

  outputs = inputs@{ self, nixpkgs, nixpkgs-unstable, home-manager, nixos-wsl
    , nix-darwin, mac-app-util, lazyvim, neovim, ... }: {
      nixosConfigurations = {
        nixos = import ./hosts/desktop { inherit inputs; };
        wsl = import ./hosts/wsl { inherit inputs; };
      };

      darwinConfigurations = {
        macbook = import ./hosts/macbook { inherit inputs; };
      };
    };
}
