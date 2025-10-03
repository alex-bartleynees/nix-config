{ config, pkgs, lib, ... }:
let cfg = config.obsidian;
in {
  options.obsidian = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Obsidian configuration.";
    };

    theme = lib.mkOption {
      type = lib.types.str;
      default = "Default";
      description = "Default Obsidian theme.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.obsidian = {
      enable = true;
      vaults.obsidian-vault = {
        enable = true;
        target = "Documents/obsidian-vault";
        settings = { appearance = { cssTheme = cfg.theme; }; };
      };
    };
  };
}
