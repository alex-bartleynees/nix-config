{ config, pkgs, lib, myUsers, username, ... }:
let cfg = config.shell;
in {
  options.shell = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable custom shell configuration.";
    };

    defaultShell = lib.mkOption {
      type = lib.types.enum [ "bash" "zsh" "fish" "nushell" ];
      default = "zsh";
      description = "Default shell to configure.";
    };

    enableBash = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Bash configuration.";
    };

    enableZsh = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Zsh configuration.";
    };

    enableFish = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Fish configuration.";
    };

    enableNushell = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Nushell configuration.";
    };

    enableTmux = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable tmux configuration.";
    };

    enableShellTools = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable common shell tools and utilities.";
    };

    enableZoxide = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable zoxide (smart cd command).";
    };

    enableAtuin = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable atuin (shell history sync).";
    };
  };

  config = lib.mkIf cfg.enable (let
    commonAliases = {
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
  in {
    programs.bash = lib.mkIf cfg.enableBash {
      enable = true;
      shellAliases = commonAliases;
    };

    programs.zsh = lib.mkIf cfg.enableZsh {
      enable = true;
      shellAliases = commonAliases;
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

    programs.fish = lib.mkIf cfg.enableFish {
      enable = true;
      shellAliases = commonAliases;
    };

    programs.nushell = lib.mkIf cfg.enableNushell {
      enable = true;
      shellAliases = commonAliases;
    };

    programs.tmux = lib.mkIf cfg.enableTmux (let
      customPlugins = {
        tokyo-night = pkgs.tmuxPlugins.mkTmuxPlugin {
          pluginName = "tmux-tokyo-night";
          version = "1.10.0";
          rtpFilePath = "tmux-tokyo-night.tmux";
          src = pkgs.fetchFromGitHub {
            owner = "fabioluciano";
            repo = "tmux-tokyo-night";
            rev = "5ce373040f893c3a0d1cb93dc1e8b2a25c94d3da";
            sha256 = "sha256-9nDgiJptXIP+Hn9UY+QFMgoghw4HfTJ5TZq0f9KVOFg=";
          };
        };
      };

      defaultShellPath =
        "/etc/profiles/per-user/${username}/bin/${cfg.defaultShell}";
    in {
      enable = true;
      prefix = "C-b";
      baseIndex = 1;
      escapeTime = 1;
      keyMode = "vi";
      mouse = true;
      customPaneNavigationAndResize = true;
      terminal = "tmux-256color";
      plugins = [
        pkgs.tmuxPlugins.sensible
        {
          plugin = customPlugins.tokyo-night;
          extraConfig = ''set -g @plugin "fabioluciano/tmux-tokyo-night"'';
        }
      ];
      extraConfig = ''
        # Set shell
        set -g default-command "${defaultShellPath} -l"
        set -g default-shell "${defaultShellPath}"

        # Terminal overrides for 256 colors
        set -ga terminal-overrides ",xterm-256color:Tc"

        # Pane splitting
        bind | split-window -h -c "#{pane_current_path}"
        bind - split-window -v -c "#{pane_current_path}"
        unbind '"'
        unbind %

        # Window management
        bind c new-window -c "#{pane_current_path}"
        bind r source-file ~/.tmux.conf
        bind p previous-window
        set -g allow-rename off

        # Alt-arrow pane switching
        bind -n M-Left select-pane -L
        bind -n M-Right select-pane -R
        bind -n M-Up select-pane -U
        bind -n M-Down select-pane -D

        # URL view
        bind u capture-pane \; save-buffer /tmp/tmux-buffer \; split-window -l 10 "urlview /tmp/tmux-buffer"

        # Vim awareness
        is_vim="ps -o state= -o comm= -t '#{pane_tty}' | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|l?n?vim?x?|fzf)(diff)?$'"
        bind-key -n 'C-h' if-shell "$is_vim" 'send-keys C-h'  'select-pane -L'
        bind-key -n 'C-j' if-shell "$is_vim" 'send-keys C-j'  'select-pane -D'
        bind-key -n 'C-k' if-shell "$is_vim" 'send-keys C-k'  'select-pane -U'
        bind-key -n 'C-l' if-shell "$is_vim" 'send-keys C-l'  'select-pane -R'
        bind-key -T copy-mode-vi 'C-h' select-pane -L
        bind-key -T copy-mode-vi 'C-j' select-pane -D
        bind-key -T copy-mode-vi 'C-k' select-pane -U
        bind-key -T copy-mode-vi 'C-l' select-pane -R
        bind-key -T copy-mode-vi 'C-\' select-pane -l
      '';
    });

    # Shell tools and utilities
    home.packages = lib.mkIf cfg.enableShellTools
      (with pkgs; [ ripgrep fd fzf btop bat bottom zoxide tmuxinator eza jq ]);

    # Zoxide configuration
    programs.zoxide = lib.mkIf cfg.enableZoxide {
      enable = true;
      enableZshIntegration = cfg.enableZsh;
      options = [ "--cmd cd" ];
    };

    # Atuin configuration
    programs.atuin = lib.mkIf cfg.enableAtuin {
      enable = true;
      enableZshIntegration = cfg.enableZsh;
      settings = {
        auto_sync = true;
        sync_frequency = "5m";
        search_mode = "prefix";
      };
    };

    # Session variables
    home.sessionVariables = lib.mkMerge [
      (lib.mkIf cfg.enable {
        NIX_BUILD_SHELL = "${pkgs.${cfg.defaultShell}}/bin/${cfg.defaultShell}";
        SHELL = "${pkgs.${cfg.defaultShell}}/bin/${cfg.defaultShell}";
      })
    ];
  });
}
