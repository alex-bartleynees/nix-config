{ pkgs, theme, ... }: {
  home.packages = with pkgs; [ ghostty ];
  home.file = {
    ".config/ghostty/config".text = ''
      background-opacity=0.9
      window-decoration=false
      theme=${theme.ghosttyTheme or theme.name}
    '';
  };

}
