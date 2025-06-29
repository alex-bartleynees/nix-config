{ config, pkgs, inputs, ... }: {
  specialisation.gnome = {
    inheritParentConfig = false;
    configuration = { config, pkgs, ... }@args:
      import ./gnome.nix (args // { inherit inputs; });
  };

  specialisation.cosmic = {
    inheritParentConfig = false;
    configuration = { config, pkgs, ... }@args:
      import ./cosmic.nix (args // { inherit inputs; });
  };

  specialisation.hyprland = {
    inheritParentConfig = false;
    configuration = { config, pkgs, ... }@args:
      import ./hypr.nix (args // { inherit inputs; });
  };
}
