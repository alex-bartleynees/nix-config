{ inputs, username ? "alexbn", homeDirectory ? "/home/alexbn"
, theme ? "catppuccin-mocha" }:

let
  baseImports = [
    ./locale.nix
    ../users/${username}.nix
    ../hosts/desktop/modules
    ../hosts/desktop/nixos/configuration.nix
    inputs.stylix.nixosModules.stylix
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
