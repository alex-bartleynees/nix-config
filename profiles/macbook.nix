{
  darwinConfig = { pkgs, self, users, ... }: {
    programs.zsh.enable = true;

    nix = {
      settings = { experimental-features = [ "nix-command" "flakes" ]; };
      optimise.automatic = true;
      gc = {
        automatic = true;
        interval = {
          Weekday = 0;
          Hour = 3;
          Minute = 15;
        };
        options = "--delete-older-than 7d";
      };
    };

    environment.systemPackages = with pkgs; [ vim git ];
    environment.shells = [ pkgs.zsh ];

    system.configurationRevision = self.rev or self.dirtyRev or null;

    system.stateVersion = 5;

    users.users = builtins.listToAttrs (map (user: {
      name = user.username;
      value = {
        home = user.homeDirectory;
        shell = pkgs.zsh;
      };
    }) users);

    services.tailscale.enable = true;

    nixpkgs.hostPlatform = "aarch64-darwin";

    networking.hostName = "macbook";
  };

  homeConfig = { pkgs, lib, ... }: lib.mkIf pkgs.stdenv.isDarwin {
    home.packages = with pkgs; [ aerospace tailscale ];

    vscode.enable = true;

    ghostty = {
      enable = true;
      theme = "Dracula+";
      windowDecoration = true;
    };

    brave = { enable = true; };

    home.file = {
      ".config/aerospace/aerospace.toml".text = ''
        start-at-login = true
        enable-normalization-flatten-containers = false
        enable-normalization-opposite-orientation-for-nested-containers = false

        on-focused-monitor-changed = ['move-mouse monitor-lazy-center']

        [gaps]
        inner.horizontal = 8
        inner.vertical =   8
        outer.left =       4
        outer.bottom =     16
        outer.top =        16
        outer.right =      4

        [mode.main.binding]
        alt-enter = 'exec-and-forget open -n "/Applications/Ghostty.app"'

        alt-j = 'focus --boundaries-action wrap-around-the-workspace left'
        alt-k = 'focus --boundaries-action wrap-around-the-workspace down'
        alt-l = 'focus --boundaries-action wrap-around-the-workspace up'
        alt-semicolon = 'focus --boundaries-action wrap-around-the-workspace right'

        alt-shift-j = 'move left'
        alt-shift-k = 'move down'
        alt-shift-l = 'move up'
        alt-shift-semicolon = 'move right'

        alt-h = 'split horizontal'
        alt-v = 'split vertical'

        alt-f = 'fullscreen'

        alt-s = 'layout v_accordion'
        alt-w = 'layout h_accordion'
        alt-e = 'layout tiles horizontal vertical'

        alt-shift-space = 'layout floating tiling'

        alt-1 = 'workspace 1'
        alt-2 = 'workspace 2'
        alt-3 = 'workspace 3'
        alt-4 = 'workspace 4'
        alt-5 = 'workspace 5'
        alt-6 = 'workspace 6'
        alt-7 = 'workspace 7'
        alt-8 = 'workspace 8'
        alt-9 = 'workspace 9'
        alt-0 = 'workspace 10'

        alt-shift-1 = 'move-node-to-workspace 1'
        alt-shift-2 = 'move-node-to-workspace 2'
        alt-shift-3 = 'move-node-to-workspace 3'
        alt-shift-4 = 'move-node-to-workspace 4'
        alt-shift-5 = 'move-node-to-workspace 5'
        alt-shift-6 = 'move-node-to-workspace 6'
        alt-shift-7 = 'move-node-to-workspace 7'
        alt-shift-8 = 'move-node-to-workspace 8'
        alt-shift-9 = 'move-node-to-workspace 9'
        alt-shift-0 = 'move-node-to-workspace 10'

        alt-shift-c = 'reload-config'

        alt-r = 'mode resize'

        [mode.resize.binding]
        h = 'resize width -50'
        j = 'resize height +50'
        k = 'resize height -50'
        l = 'resize width +50'
        enter = 'mode main'
        esc = 'mode main'
      '';
    };
  };
}
