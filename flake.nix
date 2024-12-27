{
  description = "NixOS configuration";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ghostty = {
      url = "github:ghostty-org/ghostty/4b4d4062dfed7b37424c7210d1230242c709e990";
    };
  };

  outputs = inputs@{ nixpkgs, home-manager, ghostty, ... }: {
    nixosConfigurations = {
      nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./system/hosts/desktop/nixos/configuration.nix
          ./system

          home-manager.nixosModules.home-manager
          {
          home-manager.extraSpecialArgs = {
                inherit inputs;
              };
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.alexbn = import ./home; 
            home-manager.backupFileExtension = "backup";
          }
        ];
      };
    };
  };
}
