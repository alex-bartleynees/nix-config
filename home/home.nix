{ config, pkgs, lib, inputs, username, homeDirectory, hostName, theme, myUsers
, ... }: {

  imports = [ ./modules/tmux ]
    ++ (if builtins.pathExists ./modules/${hostName} then
      [ ./modules/${hostName} ]
    else
      [ ]);

  home.username = username;
  home.homeDirectory = homeDirectory;
  home.stateVersion = "24.11";

  programs.home-manager.enable = true;

  programs.git = {
    enable = true;
    userName = myUsers.${username}.git.userName;
    userEmail = myUsers.${username}.git.userEmail;
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
    shellAliases = {
      lv = "lazyvim";
      tx = "tmuxinator";
      lg = "lazygit";
      ld = "lazydocker";
      ls = "eza --icons";
      git-work = "git config user.email '${myUsers.${username}.git.workEmail}'";
      git-personal =
        "git config user.email '${myUsers.${username}.git.userEmail}'";
      git-whoami = "git config user.email";
      rebuild-desktop =
        "sudo nixos-rebuild switch --flake ~/.config/nix-config#desktop";
      rebuild-thinkpad =
        "sudo nixos-rebuild switch --flake ~/.config/nix-config#thinkpad";
      rebuild-wsl =
        "sudo nixos-rebuild switch --flake ~/.config/nix-config#wsl";
      rebuild-media =
        "sudo nixos-rebuild switch --flake ~/.config/nix-config#media";
    };
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

  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };

  home.packages = with pkgs;
    [
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
      nerd-fonts.jetbrains-mono
      nerd-fonts.fira-code
      nerd-fonts.hack
      inputs.lazyvim.packages.${system}.default
      inputs.neovim.packages.${system}.default
      zoxide
      tmuxinator
      claude-code
      opencode
      delta
      eza
      jq
      (vim_configurable.customize {
        name = "vim";
        vimrcConfig.customRC = ''
          source $VIMRUNTIME/defaults.vim
          set clipboard=unnamedplus
        '';
      })
      wget
      git
    ] ++ lib.optionals pkgs.stdenv.isLinux [ wl-clipboard wl-clipboard-x11 ];

  programs.zoxide.options = [ "--cmd cd" ];
  programs.zoxide.enable = true;
  programs.zoxide.enableZshIntegration = true;
  programs.yazi.enable = true;

  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      auto_sync = true;
      sync_frequency = "5m";
      search_mode = "prefix";
    };
  };

  home.file = {
    ".config/nvim" = {
      source = "${inputs.dotfiles}/configs/nvim";
      recursive = true;
    };

    ".config/nvim/lua/alex/plugins/colorscheme.lua" = {
      source = "${inputs.dotfiles}/themes/${theme.name}/nvim/colorscheme.lua";
    };

    ".config/lazyvim" = {
      source = "${inputs.dotfiles}/configs/lazyvim";
      recursive = true;
    };

  };

  home.sessionVariables = {
    EDITOR = "nvim";
    BACKGROUND = theme.wallpaper;
    NIX_BUILD_SHELL = "${pkgs.zsh}/bin/zsh";
    SHELL = "${pkgs.zsh}/bin/zsh";
  };

}

