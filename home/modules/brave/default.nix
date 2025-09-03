{ pkgs, theme, ... }: {
  programs.brave = {
    enable = true;
    extensions = [
      "ienfalfjdbdpebioblfackkekamfmbnh" # angular dev tools
      "nngceckbapebfimnlniiiahkandclblb" # bitwarden
      "${theme.chromeThemeExtensionId}"
    ];
  };
}
