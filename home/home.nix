{ pkgs, lib, inputs, username, homeDirectory, hostName, theme, myUsers, desktop
, ... }:
let
  profiles = lib.concatMap (profile: [ ./profiles/${profile}.nix ])
    (if (myUsers.${username} != null && myUsers.${username}.profiles != null)
     then myUsers.${username}.profiles
     else []);
in {

  imports = profiles ++ (if builtins.pathExists ./hosts/${hostName} then
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

