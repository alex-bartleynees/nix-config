{ config, pkgs, lib, myUsers, username, ... }:
let cfg = config.git;
in {
  options.git = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable git configuration.";
    };

    defaultBranch = lib.mkOption {
      type = lib.types.str;
      default = "main";
      description = "Default branch name for new repositories.";
    };

    editor = lib.mkOption {
      type = lib.types.str;
      default = "nvim";
      description = "Default editor for git.";
    };

    enableDelta = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable delta pager for git diff.";
    };

    diffTool = lib.mkOption {
      type = lib.types.str;
      default = "vimdiff";
      description = "Default diff tool.";
    };

    enableRebasePull = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Use rebase instead of merge for git pull.";
    };

    enableUserConfig = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable user configuration from myUsers.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.git = lib.mkMerge [
      {
        enable = true;
        settings = {
          init.defaultBranch = cfg.defaultBranch;

          core = {
            editor = cfg.editor;
            whitespace = "fix,-indent-with-non-tab,trailing-space,cr-at-eol";
          } // (lib.optionalAttrs cfg.enableDelta { pager = "delta"; });

          diff = { tool = cfg.diffTool; };

          difftool = { prompt = false; };
        } // (lib.optionalAttrs cfg.enableRebasePull {
          pull = { rebase = true; };
        });
      }
      (lib.mkIf (cfg.enableUserConfig && myUsers.${username} ? git) {
        settings.user = {
          name = myUsers.${username}.git.userName;
          email = myUsers.${username}.git.userEmail;
        };
      })
    ];

    home.packages = lib.mkIf cfg.enableDelta (with pkgs; [ delta ]);
  };
}
