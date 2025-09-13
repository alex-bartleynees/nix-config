{ pkgs, inputs, ... }:
let
  theme =
    import ../../../core/themes/catppuccin-mocha.nix { inherit inputs pkgs; };
  shared = import ../../../shared/nixos-default.nix {
    inherit inputs theme;
    desktop = "river";
  };
  sharedImports = shared.getImports {
    additionalImports =
      [ ../modules ../nixos/configuration.nix { _module.args.theme = theme; } ];
  };
in {
  specialisation.river = {
    inheritParentConfig = false;
    configuration = {
      imports = sharedImports ++ [ ../../../core/desktops/river.nix ];
    };
  };
}
