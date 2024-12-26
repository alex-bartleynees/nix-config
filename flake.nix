{
	description = "NixOS configuration";
	inputs = {
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
		
		home-manager = {
			url = "github:nix-community/home-manager/release-24.11";
			inputs.nixpkgs.follows = "nixpkgs";
		};
	};

	outputs = inputs@{ nixpkgs, home-manager, ...}: {
		nixosConfigurations = {
		nixos = nixpkgs.lib.nixosSystem {
			system = "x86_64-linux";
			modules = [
				./system/hosts/desktop/nixos/configuration.nix
				./system
				
			home-manager.nixosModules.home-manager
			{
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
