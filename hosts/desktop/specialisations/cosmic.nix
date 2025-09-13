{ pkgs, inputs, ... }:
let
  theme = import ../../../core/themes/tokyo-night.nix { inherit inputs pkgs; };
  shared = import ../../../shared/nixos-default.nix {
    inherit inputs theme;
    desktop = "cosmic";
  };
  sharedImports = shared.getImports {
    additionalImports =
      [ ../modules ../nixos/configuration.nix { _module.args.theme = theme; } ];
  };
in {
  specialisation.cosmic = {
    inheritParentConfig = false;
    configuration = {
      imports = sharedImports ++ [ ../../../core/desktops/cosmic.nix ];
    };
  };
}
