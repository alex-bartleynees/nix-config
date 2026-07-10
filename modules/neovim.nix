{
  homeConfig = { config, pkgs, lib, inputs, osConfig, ... }:
    let 
      cfg = config.neovim;
      theme = osConfig.myConfig.theme;
    in {
      options.neovim = {
        enable =
          lib.mkEnableOption "neovim with nix-managed LSPs and formatters";
      };

      config = lib.mkIf cfg.enable {
        programs.neovim = {
          enable = true;
          defaultEditor = true;
          withRuby = false;
          withPython3 = false;

          plugins = with pkgs.vimPlugins; [
            telescope-nvim
            telescope-fzf-native-nvim
            telescope-ui-select-nvim
            plenary-nvim
            nvim-web-devicons
            (nvim-treesitter.withAllGrammars)
            nvim-treesitter-textobjects
            nvim-ts-autotag
          ];

          extraPackages = with pkgs; [
            # LSP servers
            lua-language-server
            nil
            pyright
            typescript-language-server
            vscode-langservers-extracted
            tailwindcss-language-server
            svelte-language-server
            graphql-language-service-cli
            emmet-ls
            angular-language-server
            astro-language-server
            helm-ls
            dockerfile-language-server
            yaml-language-server
            roslyn-ls
            fsautocomplete

            # Formatters
            prettier
            eslint_d
            nixfmt
            black
            stylua
            isort
            fantomas

            # Linters
            ruff

            # Utilities
            nodejs
          ];
        };

        home.file = {
          ".config/nvim" = {
            source = "${inputs.dotfiles}/configs/nvim";
            recursive = true;
          };

          ".config/nvim/plugin/colorscheme.lua" = {
            source =
              "${inputs.dotfiles}/themes/${theme.name}/nvim/colorscheme.lua";
          };
        };
      };
    };
}
