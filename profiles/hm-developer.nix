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

    # Sandboxed claude-code with landrun
    (pkgs.writeShellScriptBin "claude" ''
      # Create config directories if they don't exist
      mkdir -p "$HOME/.config/claude-code"
      mkdir -p "$HOME/.cache/claude"
      mkdir -p "$HOME/.claude/plugins"
      mkdir -p "$HOME/workspaces"
      touch "$HOME/.claude.json"

      # Run claude with landrun sandbox
      exec ${pkgs.landrun}/bin/landrun \
        --rox /nix/store,/usr,/run/current-system \
        --ro /etc \
        --rw "$HOME/.config/claude-code,$HOME/.cache/claude,$HOME/.claude.json,$HOME/.claude" \
        --rwx "$HOME/workspaces" \
        --rwx /tmp \
        --connect-tcp 443 \
        --env HOME \
        --env PATH \
        --env XDG_CONFIG_HOME \
        --env XDG_CACHE_HOME \
        --env USER \
        --env TERM \
        -- \
        ${pkgs.claude-code}/bin/claude "$@"
    '')

    # Sandboxed opencode with landrun
    (pkgs.writeShellScriptBin "opencode" ''
      # Create config directories if they don't exist
      mkdir -p "$HOME/.config/opencode"
      mkdir -p "$HOME/.cache/opencode"
      mkdir -p "$HOME/.local/share/opencode/log"
      mkdir -p "$HOME/workspaces"

      # Run opencode with landrun sandbox
      exec ${pkgs.landrun}/bin/landrun \
        --best-effort \
        --rox /nix/store,/usr,/run/current-system,/dev \
        --ro /etc,/sys,/proc \
        --rw "$HOME/.config/opencode,$HOME/.cache/opencode,$HOME/.local/share/opencode" \
        --rwx "$HOME/workspaces" \
        --rwx /tmp \
        --connect-tcp 443 \
        --env HOME \
        --env PATH \
        --env XDG_CONFIG_HOME \
        --env XDG_CACHE_HOME \
        --env USER \
        --env TERM \
        -- \
        ${pkgs.opencode}/bin/opencode "$@"
    '')

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
