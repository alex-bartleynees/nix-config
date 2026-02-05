# homeModule: true
{ config, lib, homeDirectory, ... }:
let cfg = config.obsidian;
in {
  options.obsidian = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Obsidian configuration.";
    };

    vaultPath = lib.mkOption {
      type = lib.types.str;
      default = "${homeDirectory}/Documents/obsidian-vault";
      description = "Absolute path to the Obsidian vault.";
    };

    theme = lib.mkOption {
      type = lib.types.str;
      default = "Default";
      description = "Default Obsidian theme.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.activation.ensureObsidianDir = lib.hm.dag.entryBefore [ "obsidian" ] ''
      mkdir -p "${homeDirectory}/.config/obsidian"
    '';

    programs.obsidian = {
      enable = true;
      vaults."${lib.removePrefix "${homeDirectory}/" cfg.vaultPath}" = {
        enable = true;
        settings = { appearance = { cssTheme = cfg.theme; }; };
      };
    };
  };
}
