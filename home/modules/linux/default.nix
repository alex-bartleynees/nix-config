
{ pkgs, inputs, ... }: {
 programs.brave = {
    enable = true;
    package = (pkgs.brave.override { commandLineArgs = [ "--disable-gpu" ]; });
  };

  home.packages = with pkgs; [
    firefox
    grim
    slurp
    feh    
    inputs.ghostty.packages."${pkgs.system}".default
    (pkgs.jetbrains.plugins.addPlugins pkgs.jetbrains.rider [
      "github-copilot"
      "ideavim"
    ])
  ];

  home.pointerCursor = {
    name = "Adwaita";
    package = pkgs.adwaita-icon-theme;
    size = 24;
  };

  fonts.fontconfig.enable = true;
}
