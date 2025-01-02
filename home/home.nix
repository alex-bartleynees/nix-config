{ config, pkgs, inputs, background, username, homeDirectory, ... }: {

  imports = [ ./modules/alacritty ./modules/tmux ];
  home.username = username;
  home.homeDirectory = homeDirectory;
  home.stateVersion = "24.11";

  programs.home-manager.enable = true;

  programs.git = {
    enable = true;
    userName = "Alex Bartley Nees";
    userEmail = "alexbartleynees@gmail.com";
    extraConfig = {
      init.defaultBranch = "main";

      core = {
        editor = "nvim";
        whitespace = "fix,-indent-with-non-tab,trailing-space,cr-at-eol";
        pager = "delta";
      };

      diff = { tool = "vimdiff"; };

      difftool = { prompt = false; };

      pull = { rebase = true; };
    };
  };

  programs.direnv = {
    enable = true;
    enableZshIntegration = true; # If you're using zsh
    nix-direnv.enable = true; # Better caching
  };

  programs.zsh = {
    enable = true;
    initExtra = "source ~/.p10k.zsh";
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

  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };

 programs.brave = {
    enable = true;
  };

  home.packages = with pkgs; [
    ripgrep
    fd
    fastfetch
    tmux
    fzf
    btop
    bat
    bottom
    lazygit
    lazydocker
    alacritty
    font-awesome
    icomoon-feather
    iosevka
    (nerdfonts.override { fonts = [ "JetBrainsMono" "FiraCode" "Hack" ]; })
  ];

  home.file = {
    ".config/nvim" = {
      source = "${inputs.dotfiles}/configs/nvim";
      recursive = true;
    };
  };

  home.sessionVariables = {
    EDITOR = "nvim";
    BACKGROUND = background.wallpaper;
    NIX_BUILD_SHELL = "${pkgs.zsh}/bin/zsh";
    SHELL = "${pkgs.zsh}/bin/zsh";
  };

}

