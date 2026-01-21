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

    # Unrestricted login helper for OAuth (not needed on macOS)
    (pkgs.writeShellScriptBin "claude-login" (if pkgs.stdenv.isLinux then ''
      exec ${pkgs.claude-code}/bin/claude /login
    '' else ''
      exec ${pkgs.claude-code}/bin/claude "$@"
    ''))

    # Sandboxed claude-code with landrun on Linux, direct on macOS
    (pkgs.writeShellScriptBin "claude" (if pkgs.stdenv.isLinux then ''
      # Create config directories if they don't exist
      mkdir -p "$HOME/.config/claude-code"
      mkdir -p "$HOME/.cache/claude"
      mkdir -p "$HOME/.local/state/claude-code"
      mkdir -p "$HOME/.claude/plugins"
      mkdir -p "$HOME/workspaces"
      touch "$HOME/.claude.json"
      touch "$HOME/.gitconfig"

      # Run claude with landrun sandbox
      exec ${pkgs.landrun}/bin/landrun \
        --best-effort \
        --rox /nix/store,/usr,/run/current-system \
        --ro /dev,/etc,/sys,/proc \
        --rw /dev/null,/dev/stdin,/dev/stdout,/dev/stderr,/dev/tty \
        --ro "$HOME/.gitconfig" \
        --rw "$HOME/.config/claude-code,$HOME/.cache/claude,$HOME/.local/state/claude-code,$HOME/.claude.json,$HOME/.claude" \
        --rwx "$HOME/.config/nix-config" \
        --rwx "$HOME/workspaces" \
        --rwx /tmp \
        --connect-tcp 443 \
        --env HOME \
        --env PATH \
        --env XDG_CONFIG_HOME \
        --env XDG_CACHE_HOME \
        --env XDG_STATE_HOME \
        --env USER \
        --env TERM \
        --env LANG \
        --env LC_ALL \
        -- \
        ${pkgs.claude-code}/bin/claude "$@"
    '' else ''
      # macOS: Run claude directly without sandboxing
      exec ${pkgs.claude-code}/bin/claude "$@"
    ''))

    # Sandboxed opencode with landrun on Linux, direct on macOS
    (pkgs.writeShellScriptBin "opencode" (if pkgs.stdenv.isLinux then ''
      # Create config directories if they don't exist
      mkdir -p "$HOME/.config/opencode"
      mkdir -p "$HOME/.cache/opencode"
      mkdir -p "$HOME/.local/share/opencode/log"
      mkdir -p "$HOME/.local/state/opencode"
      mkdir -p "$HOME/workspaces"
      touch "$HOME/.gitconfig"

      # Run opencode with landrun sandbox
      exec ${pkgs.landrun}/bin/landrun \
        --best-effort \
        --rox /nix/store,/usr,/run/current-system \
        --ro /dev,/etc,/sys,/proc \
        --rw /dev/null,/dev/stdin,/dev/stdout,/dev/stderr,/dev/tty \
        --ro "$HOME/.gitconfig" \
        --rw "$HOME/.config/opencode,$HOME/.cache/opencode,$HOME/.local/share/opencode,$HOME/.local/state/opencode" \
        --rwx "$HOME/.config/nix-config" \
        --rwx "$HOME/workspaces" \
        --rwx /tmp \
        --connect-tcp 443 \
        --env HOME \
        --env PATH \
        --env XDG_CONFIG_HOME \
        --env XDG_CACHE_HOME \
        --env XDG_STATE_HOME \
        --env USER \
        --env TERM \
        --env LANG \
        --env LC_ALL \
        -- \
        ${pkgs.opencode}/bin/opencode "$@"
    '' else ''
      # macOS: Run opencode directly without sandboxing
      exec ${pkgs.opencode}/bin/opencode "$@"
    ''))

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
