{
  description = "NixOS configuration";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    wsl-vpnkit = {
      url =
        "https://github.com/sakai135/wsl-vpnkit/releases/download/v0.4.1/wsl-vpnkit.tar.gz?narHash=sha256-VXOG5AvI2snlicoGkqcgs2QTYCD9e7/i1lL7gXbAoLY%3D";
      flake = false;
    };

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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

    neovim = { url = "github:alex-bartleynees/nix-devenv?dir=neovim"; };

    niri.url = "github:sodiboo/niri-flake";

    mango.url = "github:DreamMaoMao/mango";
  };

  outputs = inputs@{ self, nixpkgs, determinate, home-manager, nixos-wsl
    , wsl-vpnkit, nix-darwin, mac-app-util, stylix, neovim, sops-nix, disko
    , nixos-hardware, niri, mango, ... }:
    let
      mkSystem = import ./shared/mk-system.nix { inherit inputs; };
      mkDarwinSystem = import ./shared/mk-darwin-system.nix { inherit inputs; };
      allHosts = import ./hosts.nix { inherit inputs; };

      linuxHosts =
        nixpkgs.lib.filterAttrs (name: config: !(config.isDarwin or false))
        allHosts;
      darwinHosts =
        nixpkgs.lib.filterAttrs (name: config: config.isDarwin or false)
        allHosts;
    in {
      nixosConfigurations =
        nixpkgs.lib.mapAttrs (name: config: mkSystem config) linuxHosts;

      darwinConfigurations =
        nixpkgs.lib.mapAttrs (name: config: mkDarwinSystem config) darwinHosts;
    };
}
