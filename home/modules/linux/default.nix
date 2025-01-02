
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
    unstable.ghostty 
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

  home.file = {
    ".config/ghostty/config".source = ../ghostty/ghostty.linux;
  };

  fonts.fontconfig.enable = true;
}
