{ pkgs, inputs, ... }: { home.packages = with pkgs; [ pkgs.jetbrains.rider ]; }
