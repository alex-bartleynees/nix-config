{ inputs, pkgs, theme, ... }: {

  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };

  shell = {
    enable = true;
    defaultShell = "zsh";
    enableZsh = true;
    enableFish = true;
    enableNushell = true;
    enableTmux = true;
    enableZellij = true;
    zellijTheme = theme.zellijTheme or "tokyo-night-dark";
  };

  git = { enable = true; };

  direnv = { enable = true; };

  home.packages = with pkgs; [
    fastfetch
    tmux
    lazygit
    lazydocker
    inputs.neovim.packages.${pkgs.stdenv.hostPlatform.system}.default
    claude-code
    opencode
    restic-browser
    dbeaver-bin
    (vim-full.customize {
      name = "vim";
      vimrcConfig.customRC = ''
        source $VIMRUNTIME/defaults.vim
        set clipboard=unnamedplus
      '';
    })
    wget
    git

  ];

  programs.yazi.enable = true;

  home.file = {
    ".config/nvim" = {
      source = "${inputs.dotfiles}/configs/nvim";
      recursive = true;
    };

    ".config/nvim/lua/alex/plugins/colorscheme.lua" = {
      source = "${inputs.dotfiles}/themes/${theme.name}/nvim/colorscheme.lua";
    };
  };

  home.sessionVariables = { EDITOR = "nvim"; };
}
