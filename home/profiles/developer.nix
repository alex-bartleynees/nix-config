{ inputs, pkgs, theme, ... }: {
  imports = [ ../modules/tmux ../modules/git ../modules/direnv ../modules/zsh ];

  programs.neovim = {
    enable = true;
    defaultEditor = true;
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
    inputs.lazyvim.packages.${system}.default
    inputs.neovim.packages.${system}.default
    zoxide
    tmuxinator
    claude-code
    #opencode
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

  ];

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
    NIX_BUILD_SHELL = "${pkgs.zsh}/bin/zsh";
    SHELL = "${pkgs.zsh}/bin/zsh";
  };
}
