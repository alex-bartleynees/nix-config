{ config, pkgs, inputs, ... }: {
  specialisation.gnome = {
    inheritParentConfig = false;
    configuration = { config, pkgs, ... }@args:
      import ./gnome.nix (args // { inherit inputs; });
  };

  specialisation.kde = {
    inheritParentConfig = false;
    configuration = { config, pkgs, ... }@args:
      import ./kde.nix (args // { inherit inputs; });
  };

  specialisation.cosmic = {
    inheritParentConfig = false;
    configuration = { config, pkgs, ... }@args:
      import ./cosmic.nix (args // { inherit inputs; });
  };
}
