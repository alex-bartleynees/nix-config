{ config, lib, pkgs, inputs, ... }:
let
  theme =
    import ../../../core/themes/catppuccin-mocha.nix { inherit inputs pkgs; };
  shared = import ../../../shared/nixos-default.nix {
    inherit inputs theme;
    desktop = "sway";
  };
  sharedImports = shared.getImports {
    additionalImports =
      [ ../modules ../nixos/configuration.nix { _module.args.theme = theme; } ];
  };
in {
  specialisation.sway = {
    inheritParentConfig = false;
    configuration = {
      imports = sharedImports ++ [ ../../../core/desktops/sway.nix ];
    };
  };
}
