# homeModule: true
{ pkgs, ... }: {
  home.packages = with pkgs; [ yaak azuredatastudio ];
}
