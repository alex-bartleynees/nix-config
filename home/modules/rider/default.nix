{ pkgs, inputs, ... }: {
  home.packages = with pkgs;
    [
      (pkgs.jetbrains.plugins.addPlugins
        pkgs.jetbrains.rider [ "github-copilot" "ideavim" ])
    ];
}
