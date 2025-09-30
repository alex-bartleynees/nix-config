{ pkgs, ... }: {
  imports = [
    ../../modules/obsidian
    ../../modules/ghostty
    ../../modules/brave
    ../../modules/alacritty
  ];

  home.packages = with pkgs; [
    firefox
    vlc
    pavucontrol
    pulsemixer
    xfce.tumbler
    xfce.ristretto
    popsicle
  ];

  stylix.targets.vscode.enable = false;
}
