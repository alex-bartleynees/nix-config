{ pkgs, inputs, ... }: {
  imports = [ ../rider ../obsidian ];

  programs.zsh.shellAliases = {
    git-work = "git config user.email 'alexander.nees@valocityglobal.com'";
    git-personal = "git config user.email 'alexbartleynees@gmail.com'";
    git-whoami = "git config user.email";
  };
}
