{ pkgs, lib, inputs, username, homeDirectory, hostName, theme, myUsers, desktop
, ... }: {

  imports = [ ./modules/tmux ]
    ++ (if builtins.pathExists ./hosts/${hostName} then
      [ ./hosts/${hostName} ]
    else
      [ ])
    ++ (if desktop != null && builtins.pathExists ./desktops/${desktop} then
      [ ./desktops/${desktop} ]
    else
      [ ]);

  home.username = lib.mkDefault username;
  home.homeDirectory = lib.mkDefault homeDirectory;
  home.stateVersion = "24.11";

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    font-awesome
    icomoon-feather
    iosevka
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    nerd-fonts.hack
  ];

  home.sessionVariables = { BACKGROUND = theme.wallpaper; };

}

