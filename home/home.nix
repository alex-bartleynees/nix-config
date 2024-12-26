{config, pkgs, ...}: {

        imports = [
          ./modules/alacritty
	  ./modules/tmux
	  ./modules/vscode
        ];
	home.username = "alexbn";
	home.homeDirectory = "/home/alexbn";
        home.stateVersion = "24.11";
        home.pointerCursor = {
           name = "Adwaita";  
           package = pkgs.adwaita-icon-theme;
           size = 24;
        };

	programs.home-manager.enable = true;

	programs.git = {
		enable = true;
		userName = "Alex Bartley Nees";
		userEmail = "alexbartleynees@gmail.com";
              };

          programs.direnv = {
               enable = true;
               enableZshIntegration = true;  # If you're using zsh
               nix-direnv.enable = true;     # Better caching
            };

        programs.zsh = {
		enable = true;
                initExtra = "source ~/.p10k.zsh";
                oh-my-zsh = {
                  enable = true;
                  plugins = [
                    "git"
                    "tmux"
                  ];
                };
		plugins = [{
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

	programs.brave = {
		enable= true;
 	 package = (pkgs.brave.override {
    	commandLineArgs = ["--disable-gpu"];
  		});
	};

	home.packages = with pkgs; [
		firefox
		ripgrep
		fd
		grim
		slurp
		wl-clipboard
		fastfetch
                tmux
                fzf
                btop
                bat
                bottom
                lazygit
                lazydocker
                k9s

		networkmanagerapplet
		blueman
		udiskie

		alacritty
		waybar

		pulseaudio

		swaybg
		rofi-wayland
		dunst
		swayidle
                swaylock
                sway-audio-idle-inhibit
		
		font-awesome
		(nerdfonts.override { fonts = [
			"JetBrainsMono"
			"FiraCode"
		];})
              ];

        home.sessionVariables = {
          EDITOR = "nvim";
          BACKGROUND= "${config.home.homeDirectory}/dotfiles/backgrounds/catppuccintotoro.png";
          NIX_BUILD_SHELL = "${pkgs.zsh}/bin/zsh";
          SHELL = "${pkgs.zsh}/bin/zsh";
        };

	fonts.fontconfig.enable = true;
}


