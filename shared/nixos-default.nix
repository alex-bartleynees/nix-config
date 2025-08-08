{ inputs, username ? "alexbn", homeDirectory ? "/home/alexbn"
, theme ? "catppuccin-mocha" }:

let
  baseImports = [
    ./locale.nix
    ./custom-options.nix
    ../users/${username}.nix
    ../hosts/desktop/modules
    ../hosts/desktop/nixos/configuration.nix
    inputs.stylix.nixosModules.stylix
    inputs.sops-nix.nixosModules.sops
  ];

  homeManagerImports = import ./home-manager.nix {
    inherit inputs username homeDirectory;
    extraModules = [ ../home ];
    inherit theme;
  };

in {
  getImports = { additionalImports ? [ ] }:
    baseImports ++ homeManagerImports ++ additionalImports;
}
