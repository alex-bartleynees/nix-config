{ config, lib, pkgs, inputs, ... }:
let
  shared = import ../../../shared/nixos-default.nix { inherit inputs; };
  sharedImports = shared.getImports {
    additionalImports = [ ../modules ../nixos/configuration.nix ];
  };
in {
  specialisation.cosmic = {
    inheritParentConfig = false;
    configuration = {
      imports = sharedImports ++ [ ../../../core/desktops/cosmic.nix ];
    };
  };
}
