{ config, ... }: {
  specialisation = { gnome.configuration = import ./gnome.nix; };
}
