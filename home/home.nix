{ config, pkgs, inputs, background, username, homeDirectory, hostName, theme
, ... }: {

  imports = [ ./modules/alacritty ./modules/tmux ]
    ++ (if builtins.pathExists ./modules/${hostName} then
      [ ./modules/${hostName} ]
    else
      [ ]);

  home.username = username;
  home.homeDirectory = homeDirectory;
  home.stateVersion = "24.11";

  programs.home-manager.enable = true;

  programs.git = {
    enable = true;
    userName = "Alex Bartley Nees";
    userEmail = "alexbartleynees@gmail.com";
    extraConfig = {
      init.defaultBranch = "main";

      core = {
        editor = "nvim";
        whitespace = "fix,-indent-with-non-tab,trailing-space,cr-at-eol";
        pager = "delta";
      };

      diff = { tool = "vimdiff"; };

      difftool = { prompt = false; };

      pull = { rebase = true; };
    };
  };

  programs.direnv = {
    enable = true;
    enableZshIntegration = true; # If you're using zsh
    nix-direnv.enable = true; # Better caching
  };

  programs.zsh = {
    enable = true;
    shellAliases = {
      lv = "lazyvim";
      tx = "tmuxinator";
    };
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
    alacritty
    font-awesome
    icomoon-feather
    iosevka
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    nerd-fonts.hack
    inputs.lazyvim.packages.${system}.default
    inputs.neovim.packages.${system}.default
    zoxide
    tmuxinator
    claude-code
    delta
  ];

  programs.zoxide.options = [ "--cmd cd" ];
  programs.zoxide.enable = true;
  programs.zoxide.enableZshIntegration = true;

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
      source = "${inputs.dotfiles}/themes/${theme}/nvim/colorscheme.lua";
    };

    ".config/lazyvim" = {
      source = "${inputs.dotfiles}/configs/lazyvim";
      recursive = true;
    };

    ".ssh/id_ed25519.pub".text =
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFKxSGAbg6Dw8DqxiPGikz9ZoXDBI6YvV80L5B1NsQ72 alexbartleynees@gmail.com";

    ".ssh/id_work.pub".text =
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICiiLMs/3ZZ8CDseUprOV5OzFJovG9GcP96GBg3HlQj+ alexander.nees@valocityglobal.com";
  };

  home.sessionVariables = {
    EDITOR = "nvim";
    BACKGROUND = background.wallpaper;
    NIX_BUILD_SHELL = "${pkgs.zsh}/bin/zsh";
    SHELL = "${pkgs.zsh}/bin/zsh";
    ASPNETCORE_Kestrel__Certificates__Default__Path =
      "/mnt/c/Users/AlexanderNees/.aspnet/https/gateway+6.p12";
    ASPNETCORE_Kestrel__Certificates__Default__Password = "changeit";
  };

}

