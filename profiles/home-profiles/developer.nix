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

  distrobox = { enable = pkgs.stdenv.isLinux; };

  claude-code = {
    enable = true;
    enableSandbox = pkgs.stdenv.isLinux;
  };

  opencode = {
    enable = true;
    enableSandbox = pkgs.stdenv.isLinux;
  };

  home.packages = with pkgs; [
    fastfetch
    tmux
    lazygit
    lazydocker
    inputs.neovim.packages.${pkgs.stdenv.hostPlatform.system}.default

    restic
    (pkgs.symlinkJoin {
      name = "restic-browser-wrapped";
      paths = [ pkgs.restic-browser ];
      buildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/Restic-Browser \
          --set WEBKIT_DISABLE_DMABUF_RENDERER 1
      '';
    })
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

  programs.yazi = {
    enable = true;
    shellWrapperName = "y";
  };

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
