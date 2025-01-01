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
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    # this is a quick util a good GitHub samaritan wrote to solve for
    # https://github.com/nix-community/home-manager/issues/1341#issuecomment-1791545015
    mac-app-util = {
      url = "github:hraban/mac-app-util";
    };

    ghostty = {
      url =
        "github:ghostty-org/ghostty/4b4d4062dfed7b37424c7210d1230242c709e990";
    };

    dotfiles = {
      url = "github:alex-bartleynees/dotfiles";
      flake = false;
    };
  };

  outputs = inputs@{ self, nixpkgs, nixpkgs-unstable, home-manager, ghostty, nixos-wsl
    , nix-darwin, mac-app-util, ... }: {
      nixosConfigurations = {
        nixos = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            background = import ./shared/background.nix { inherit inputs; };
          };
          modules = [
            ./system/hosts/desktop/nixos/configuration.nix
            ./system/hosts/desktop/modules            
            ./shared/locale.nix
            ./users/alexbn.nix

            home-manager.nixosModules.home-manager
            ({ config, ... }: {
              home-manager.extraSpecialArgs = {
                inherit inputs;
                inherit (config.networking) hostName;
                background = import ./shared/background.nix { inherit inputs; };
              };
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.alexbn = { config, pkgs, ... }: {
                imports = [ ./home ./home/modules/desktop ];
              };
              home-manager.backupFileExtension = "backup";
            })
          ];
        };

        wsl = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            nixos-wsl.nixosModules.wsl
            ./system/hosts/wsl/nixos/configuration.nix
            ./shared/locale.nix
            ./users/alexbn.nix

            home-manager.nixosModules.home-manager
            ({ config, pkgs, ... }: {
              nixpkgs.overlays = [
                (final: prev: {
                  unstable =
                    inputs.nixpkgs-unstable.legacyPackages.${prev.system};
                })
              ];
            })
            ({ config, ... }: {
              home-manager.extraSpecialArgs = {
                inherit inputs;
                inherit (config.networking) hostName;
                background = import ./shared/background.nix { inherit inputs; };
              };
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.alexbn = { config, pkgs, ... }: {
                imports = [ ./home ];
              };
              home-manager.backupFileExtension = "backup";
            })
          ];
        };
      };

      darwinConfigurations = {
       macbook = nix-darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          modules = [
            mac-app-util.darwinModules.default 
            ./system/hosts/macbook/configuration.nix
            ./users/alexbn.nix
          ];
          _module.args.self = self;
        }
        home-manager.darwinModules.home-manager
        {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              users.users.alexbn = {
                ignoreShellProgramCheck = true;
                home = "/Users/alexbn";
            };
              home-manager.users.alexbn = { config, pkgs, ... }: {
              imports = [ ./home ];
              };
          };
      };

    };
}
