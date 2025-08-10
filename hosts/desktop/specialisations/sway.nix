{ config, lib, pkgs, inputs, ... }:
let
  shared = import ../../../shared/nixos-default.nix { inherit inputs; };
  sharedImports = shared.getImports {
    additionalImports =
      [ ../modules/regreet.nix ../modules ../nixos/configuration.nix ];
  };
in {
  specialisation.sway = {
    inheritParentConfig = false;
    configuration = {
      imports = sharedImports ++ [ ../../../core/desktops/sway.nix ];
    };
  };
}
