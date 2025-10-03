{ config, lib, ... }:
let cfg = config.direnv;
in {
  options.direnv = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable direnv configuration.";
    };

    enableZshIntegration = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable direnv integration with Zsh.";
    };

    enableBashIntegration = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable direnv integration with Bash.";
    };

    enableNushellIntegration = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable direnv integration with Nushell.";
    };

    enableNixDirenv = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable nix-direnv for better caching.";
    };

    silent = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable silent mode, disabling direnv logging.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.direnv = {
      enable = true;
      enableZshIntegration = cfg.enableZshIntegration;
      enableBashIntegration = cfg.enableBashIntegration;
      enableNushellIntegration = cfg.enableNushellIntegration;
      nix-direnv.enable = cfg.enableNixDirenv;
      silent = cfg.silent;
    };
  };
}
