{ inputs, ... }: {
  theme = {
    name = "tokyo-night";
    wallpaper =
      "${inputs.dotfiles}/backgrounds/3--Milad-Fakurian-Abstract-Purple-Blue.jpg";
    base16Scheme = "${pkgs.base16-schemes}/share/themes/tokyo-night-storm.yaml";
  };
}
