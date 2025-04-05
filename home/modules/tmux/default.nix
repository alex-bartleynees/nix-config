{ pkgs, username, ... }:

let customPlugins = import ./plugins.nix { inherit pkgs; };
in {
  programs.tmux = {
    enable = true;
    prefix = "C-b";
    baseIndex = 1;
    escapeTime = 1;
    keyMode = "vi";
    mouse = true;
    customPaneNavigationAndResize = true;
    terminal = "xterm-256color";
    plugins = [
      pkgs.tmuxPlugins.sensible
      {
        plugin = customPlugins.tokyo-night;
        extraConfig = ''set -g @plugin "fabioluciano/tmux-tokyo-night"'';
      }
    ];
    extraConfig = ''
      # Set shell
      set -g default-command "/etc/profiles/per-user/${username}/bin/zsh -l"
      set -g default-shell "/etc/profiles/per-user/${username}/bin/zsh"

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
      is_vim="ps -o state= -o comm= -t '#{pane_tty} | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|l?n?vim?x?|fzf)(diff)?$'"
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
  };
}
