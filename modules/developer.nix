{
  homeConfig = { inputs, config, lib, pkgs, osConfig, userProfiles ? [ ], ... }:
    let
      theme = osConfig.myConfig.theme;
      cfg = config.developer;
    in {
      options.developer = {
        enable = lib.mkEnableOption "Developer configuration";
      };

      config = lib.mkMerge [
        (lib.mkIf (builtins.elem "developer" userProfiles) {
          developer.enable = true;
        })
        (lib.mkIf cfg.enable {
          neovim = { enable = true; };

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

          services.ssh-agent.enable = true;

          distrobox = { enable = pkgs.stdenv.isLinux; };

          claude-code = {
            enable = true;
            enableSandbox = pkgs.stdenv.isLinux;
          };

          opencode = {
            enable = true;
            enableSandbox = pkgs.stdenv.isLinux;
          };

          home.packages = with pkgs;
            [
              (vim-full.customize {
                name = "vim";
                vimrcConfig.customRC = ''
                  source $VIMRUNTIME/defaults.vim
                  set clipboard=unnamedplus
                '';
              })
            ];

          programs.yazi = {
            enable = true;
            shellWrapperName = "y";
          };
        })
      ];
    };
}
