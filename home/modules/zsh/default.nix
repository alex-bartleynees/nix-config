{ lib, pkgs, myUsers, username, ... }: {
  programs.zsh = {
    enable = true;
    shellAliases = {
      lv = "lazyvim";
      tx = "tmuxinator";
      lg = "lazygit";
      ld = "lazydocker";
      ls = "eza --icons";
      git-whoami = "git config user.email";
      rebuild-desktop =
        "sudo nixos-rebuild switch --flake ~/.config/nix-config#desktop";
      rebuild-thinkpad =
        "sudo nixos-rebuild switch --flake ~/.config/nix-config#thinkpad";
      rebuild-wsl =
        "sudo nixos-rebuild switch --flake ~/.config/nix-config#wsl";
      rebuild-media =
        "sudo nixos-rebuild switch --flake ~/.config/nix-config#media";
    } // (lib.optionalAttrs (myUsers.${username} ? git) {
      git-work = "git config user.email '${myUsers.${username}.git.workEmail}'";
      git-personal =
        "git config user.email '${myUsers.${username}.git.userEmail}'";
    });
    initContent = "source ~/.p10k.zsh";
    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "tmux" ];
    };
    plugins = [
      {
        name = "powerlevel10k";
        src = pkgs.zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
      {
        name = "zsh-syntax-highlighting";
        src = pkgs.zsh-syntax-highlighting;
        file = "share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh";
      }
      {
        name = "zsh-autosuggestions";
        src = pkgs.zsh-autosuggestions;
        file = "share/zsh-autosuggestions/zsh-autosuggestions.zsh";
      }
      {
        name = "fzf-tab";
        src = pkgs.zsh-fzf-tab;
        file = "share/fzf-tab/fzf-tab.plugin.zsh";
      }
    ];
  };

}
