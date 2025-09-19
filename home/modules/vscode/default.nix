{ pkgs, lib, theme, ... }:
let
  font = "JetBrains Mono";
  terminalFont = "JetBrains Mono";
  iconTheme = "material-icon-theme";

  ext = publisher: name: version: sha256:
    pkgs.vscode-utils.buildVscodeMarketplaceExtension {
      mktplcRef = { inherit name publisher sha256 version; };
    };
in {
  programs.vscode = {
    enable = true;
    profiles.default.enableExtensionUpdateCheck = true;

    profiles.default.extensions = (with pkgs.vscode-extensions; [
      bbenoist.nix
      jnoortheen.nix-ide
      bradlc.vscode-tailwindcss
      denoland.vscode-deno
      editorconfig.editorconfig
      esbenp.prettier-vscode
      github.vscode-github-actions
      github.github-vscode-theme
      golang.go
      hashicorp.terraform
      matthewpi.caddyfile-support
      prisma.prisma
      phoenixframework.phoenix
      #rust-lang.rust-analyzer
      tamasfe.even-better-toml
      thenuprojectcontributors.vscode-nushell-lang
      unifiedjs.vscode-mdx
      formulahendry.auto-rename-tag
      catppuccin.catppuccin-vsc
      zhuangtongfa.material-theme
      ms-vscode-remote.remote-ssh
      ms-vscode-remote.remote-ssh-edit
      ms-vscode-remote.vscode-remote-extensionpack
      ms-vscode-remote.remote-wsl
      ms-dotnettools.vscode-dotnet-runtime
      ms-dotnettools.csharp
      ms-dotnettools.csdevkit
      ms-azuretools.vscode-docker
      dbaeumer.vscode-eslint
      eamodio.gitlens
      ms-vsliveshare.vsliveshare
      angular.ng-template
      csharpier.csharpier-vscode
      github.copilot
      github.copilot-chat
      ms-dotnettools.vscodeintellicode-csharp
      christian-kohler.npm-intellisense
      ms-kubernetes-tools.vscode-kubernetes-tools
      # ms-python.python
      # ms-python.pylint
      # ms-python.debugpy
      svelte.svelte-vscode
      vscodevim.vim
      arcticicestudio.nord-visual-studio-code
    ]) ++ [
      # Extensions not in Nixpkgs
      (ext "andrejunges" "Handlebars" "0.4.1"
        "sha256-Rwhr9X3sjDm6u/KRYE2ucCJSlZwsgUJbH/fdq2WZ034=")
      (ext "antfu" "theme-vitesse" "0.8.3"
        "sha256-KkpJgJBcnMeQ1G97QS/E6GY4/p9ebZRaA5pUXPd9JB0=")
      (ext "astro-build" "astro-vscode" "2.8.5"
        "sha256-mP+MKHDirgemcexSCof/Be7YN2FTXwOnGQHnmtKLgtM=")
      (ext "oven" "bun-vscode" "0.0.12"
        "sha256-8+Fqabbwup6Jzm5m8GlWbxTqumqXtWAw5s3VaDht9Us=")
      (ext "b4dM4n" "nixpkgs-fmt" "0.0.1"
        "sha256-vz2kU36B1xkLci2QwLpl/SBEhfSWltIDJ1r7SorHcr8=")
      (ext "enkia" "tokyo-night" "1.0.6"
        "sha256-VWdUAU6SC7/dNDIOJmSGuIeffbwmcfeGhuSDmUE7Dig=")
      (ext "gleam" "gleam" "2.10.0"
        "sha256-Xlgtfo0d6gjYsfggNYHjUjsFB1y6/KPJeM3ZgEEBxXk=")
      (ext "Guyutongxue" "lalrpop-syntax-highlight" "0.0.5"
        "sha256-VJBvR9pM0NPYi/RUoVQcL1tt2PZCKohwX8Dd1nz0UGY=")
      (ext "hashicorp" "hcl" "0.3.2"
        "sha256-cxF3knYY29PvT3rkRS8SGxMn9vzt56wwBXpk2PqO0mo=")
      (ext "JakeBecker" "elixir-ls" "0.17.10"
        "sha256-4/B70DyNlImz60PSTSL5CKihlOJen/tR1/dXGc3s1ZY=")
      (ext "jeff-hykin" "better-nix-syntax" "1.0.7"
        "sha256-vqfhUIjFBf9JvmxB4QFrZH4KMhxamuYjs5n9VyW/BiI=")
      (ext "markusylisiurunen" "githubdarkmode" "0.1.6"
        "sha256-Xzh8g5bEi4kPul1nJyROcN0CeDnXuNxQEYt6HgMepvM=")
      (ext "mkhl" "direnv" "0.17.0"
        "sha256-9sFcfTMeLBGw2ET1snqQ6Uk//D/vcD9AVsZfnUNrWNg=")
      (ext "ms-vscode" "vscode-typescript-next" "5.4.20231127"
        "sha256-UVuYggzeWyQTmQxXdM4sT78FUOtYGKD4SzREntotU5g=")
      (ext "nefrob" "vscode-just-syntax" "0.3.0"
        "sha256-WBoqH9TNco9lyjOJfP54DynjmYZmPUY+YrZ1rQlC518=")
      (ext "PKief" "material-icon-theme" "4.32.0"
        "sha256-6I9/nWv449PgO1tHJbLy/wxzG6BQF6X550l3Qx0IWpw=")
      (ext "adrianwilczynski" "user-secrets" "2.0.1"
        "sha256-wMdQCmoMbh0K2S46A8ZFFqYVsWxnTg+UPZLjneZFWHc=")
      (ext "formulahendry" "dotnet" "0.0.4"
        "sha256-RSkhCfpl81BtGnrSZ0luHFYvoNH4qGg7pd4xU53sXLA=")
      (ext "ms-vscode" "vscode-node-azure-pack" "1.2.0"
        "sha256-FC4DuteWflPwlYFxgDHubNC3zPsA2X2zus6PMGmyOQs=")
      (ext "kreativ-software" "csharpextensions" "1.7.3"
        "sha256-qv2BbcT07cogjlLVFOKj0masRRU28krbQ5LWcFrcgQw=")
      (ext "wallabyjs" "console-ninja" "1.0.376"
        "sha256-Gg7PHaP1smey6KyQu7rAzFa+rW6LBSqdqnqYVDsUE/c=")
      (ext "ms-playwright" "playwright" "1.1.12"
        "sha256-B6RYsDp1UKZmBRT/GdTPqxGOyCz2wJYKAqYqSLsez+w=")
      (ext "monokai" "theme-monokai-pro-vscode" "2.0.5"
        "sha256-H79KlUwhgAHBnGucKq8TJ1olDl0dRrq+ullGgRV27pc=")
      (ext "donjayamanne" "python-extension-pack" "1.7.0"
        "sha256-ewOw6nMVzNSYddLcCBGKVNvllztFwhEtncE2RFeFcOc=")
      (ext "saoudrizwan" "claude-dev" "3.11.1"
        "sha256-W9XuAp2l+PQG3URQTMoqwBMIGKwI6VumppjuTrPSmuk=")
      (ext "Sourcegraph" "amp" "0.0.1748016644"
        "sha256-avI4SiNHSgHZMqGrZjC7vaBhocO2kU4Dqoejpwt1cRk=")
      (ext "sainnhe" "everforest" "0.3.0"
        "sha256-nZirzVvM160ZTpBLTimL2X35sIGy5j2LQOok7a2Yc7U=")
    ];

    profiles.default.keybindings = [
      {
        "key" = "ctrl+e";
        "command" = "workbench.action.toggleSidebarVisibility";
      }
      {
        "key" = "ctrl+shift+f";
        "command" = "workbench.action.quickTextSearch";
      }
    ];

    mutableExtensionsDir = false;

    profiles.default.userSettings = {
      "[nix]" = {
        "enableLanguageServer" = true;
        "serverPath" = "nil";
        "editor.defaultFormatter" = "B4dM4n.nixpkgs-fmt";
        "editor.formatOnSave" = true;
      };
      "[rust]" = {
        "editor.defaultFormatter" = "rust-lang.rust-analyzer";
        "editor.formatOnSave" = true;
      };
      "[toml]" = {
        "editor.defaultFormatter" = "tamasfe.even-better-toml";
        "editor.formatOnSave" = true;
      };
      "[svelte]" = { "editor.defaultFormatter" = "svelte.svelte-vscode"; };
      "[astro]" = { "editor.defaultFormatter" = "astro-build.astro-vscode"; };
      "editor.wordWrap" = "wordWrapColumn";
      "editor.wordWrapColumn" = 120;
      "search.exclude" = {
        "**/.direnv" = true;
        "**/.git" = true;
        "**/node_modules" = true;
        "*.lock" = true;
        "dist" = true;
        "tmp" = true;
      };
      "rust-analyzer.server.path" = "rust-analyzer";
      "editor.defaultFormatter" = "esbenp.prettier-vscode";
      "terminal.integrated.fontFamily" = terminalFont;
      "window.autoDetectColorScheme" = false;
      "workbench.colorTheme" =
        lib.mkDefault (theme.codeTheme or "Monokai Pro (Filter Spectrum)");
      "workbench.iconTheme" = iconTheme;
      "files.autoSave" = "onFocusChange";
      "editor.formatOnPaste" = true;
      "editor.formatOnSave" = true;
      "files.associations" = { "*.cs" = "csharp"; };
      "dotnet.enableTelemetry" = false;
      "workbench.editor.showTabs" = "single";
      "csharpextensions.useFileScopedNamespace" = true;
      "terminal.integrated.env.linux" = { };
      "editor.linkedEditing" = true;
      "nixpkgs-fmt.path" =
        "/nix/store/gad8bd4kdl5ib13091yfjyb8s9nbpxzf-nixfmt-0.6.0-bin/bin/nixfmt";
      "svelte.enable-ts-plugin" = true;
      "terminal.integrated.env.osx" = { };
      "password-store" = "gnome-libsecret";
    };
  };
}
