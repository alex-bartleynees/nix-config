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

    vscode-server = { url = "github:nix-community/nixos-vscode-server"; };

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mac-app-util = {
      url = "github:hraban/mac-app-util";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.cl-nix-lite.inputs.nixpkgs.follows = "nixpkgs";
      inputs.treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
    };

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

    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mango = {
      url = "github:DreamMaoMao/mango";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    waybar = {
      url = "github:Alexays/Waybar";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    microvm = {
      url = "github:microvm-nix/microvm.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    netclaw = {
      url = "github:alex-bartleynees/netclaw-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs:
    let
      inherit (inputs) nixpkgs;
      lib = nixpkgs.lib;
      mkSystem = import ./lib/mk-system.nix { inherit inputs; };
      mkDarwinSystem = import ./lib/mk-darwin-system.nix { inherit inputs; };
      allHosts = import ./hosts.nix { inherit inputs; };

      linuxHosts =
        lib.filterAttrs (name: config: !(config.isDarwin or false)) allHosts;
      darwinHosts =
        lib.filterAttrs (name: config: config.isDarwin or false) allHosts;

      microvmConfigs = lib.mapAttrs' (file: _:
        lib.nameValuePair (lib.removeSuffix ".nix" file)
        (import ./microvms/${file} { inherit inputs; }))
        (lib.filterAttrs (n: t: t == "regular" && lib.hasSuffix ".nix" n)
          (builtins.readDir ./microvms));
    in {
      nixosConfigurations =
        (lib.mapAttrs (name: config: mkSystem config) linuxHosts)
        // microvmConfigs;

      darwinConfigurations =
        lib.mapAttrs (name: config: mkDarwinSystem config) darwinHosts;
    };
}
