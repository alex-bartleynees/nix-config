{ pkgs, inputs, ... }: {
  home.packages = with pkgs;
    [
      (pkgs.unstable.jetbrains.plugins.addPlugins
        pkgs.unstable.jetbrains.rider [ "github-copilot" "ideavim" ])
    ];
}
