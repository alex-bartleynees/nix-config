{ pkgs, inputs, ... }:
let
  theme = import ../../../core/themes/tokyo-night.nix { inherit inputs pkgs; };
  shared = import ../../../shared/nixos-default.nix {
    inherit inputs theme;
    desktop = "gnome";
  };
  sharedImports = shared.getImports {
    additionalImports =
      [ ../modules ../nixos/configuration.nix { _module.args.theme = theme; } ];
  };
in {
  specialisation.gnome = {
    inheritParentConfig = false;
    configuration = {
      imports = sharedImports ++ [ ../../../core/desktops/gnome.nix ];
    };
  };

}
