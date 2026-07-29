{ config, lib, pkgs, ... }:
let cfg = config.syncthing;
in {
  options.syncthing = {
    enable = lib.mkEnableOption "Syncthing file synchronization";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.syncthing;
      defaultText = lib.literalExpression "pkgs.syncthing";
      description = "Syncthing package to use.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "syncthing";
      description = "User account under which Syncthing runs.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "syncthing";
      description = "Group under which Syncthing runs.";
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/syncthing";
      description =
        "Default directory for synchronized folders and service data.";
    };

    configDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/syncthing";
      description =
        "Directory containing Syncthing's configuration and identity.";
    };

    databaseDir = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Optional directory for the Syncthing database.";
    };

    gui = {
      address = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.1:8384";
        description =
          "Address and port on which the Syncthing web GUI listens.";
      };

      openFirewall = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Open the configured GUI TCP port in the firewall.";
      };

      firewallPort = lib.mkOption {
        type = lib.types.port;
        default = 8384;
        description = "TCP port to open when gui.openFirewall is enabled.";
      };

      passwordFile = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "/run/secrets/syncthing-gui-password";
        description = ''
          File containing the GUI password. Prefer this over placing a password
          directly in settings.gui.password, which would expose it in the Nix store.
        '';
      };
    };

    openDefaultPorts = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Open Syncthing's default discovery and transfer ports in the firewall.
        This does not open the web GUI port.
      '';
    };

    overrideDevices = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description =
        "Remove devices added outside the declarative configuration.";
    };

    overrideFolders = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description =
        "Remove folders added outside the declarative configuration.";
    };

    settings = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
      example = lib.literalExpression ''
        {
          gui.user = "alex";
          options.urAccepted = -1;
          devices.laptop.id = "DEVICE-ID";
          folders.Documents = {
            path = "/home/alex/Documents";
            devices = [ "laptop" ];
            ignorePerms = false;
          };
        }
      '';
      description = ''
        Declarative Syncthing configuration. This is forwarded to
        services.syncthing.settings and supports devices, folders, GUI options,
        global options, versioning, and encrypted folder device entries.
      '';
    };

    identity = {
      keyFile = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "/run/secrets/syncthing/key.pem";
        description =
          "Private key file used to give this node a stable device ID.";
      };

      certFile = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "/run/secrets/syncthing/cert.pem";
        description = "Certificate file paired with identity.keyFile.";
      };
    };

    extraFlags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "--no-default-folder" ];
      description = ''
        Additional command-line flags. The --no-default-folder flag is only
        valid with Syncthing versions older than 2.0.
      '';
    };

    systemService = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Run Syncthing as a system service.";
    };

    relay = {
      enable = lib.mkEnableOption "the Syncthing relay service";

      options = lib.mkOption {
        type = lib.types.attrsOf lib.types.anything;
        default = { };
        description =
          "Additional options forwarded to services.syncthing.relay.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [{
      assertion = (cfg.identity.keyFile == null)
        == (cfg.identity.certFile == null);
      message =
        "syncthing.identity.keyFile and syncthing.identity.certFile must be configured together";
    }];

    services.syncthing = {
      enable = true;
      inherit (cfg)
        package user group dataDir configDir openDefaultPorts overrideDevices
        overrideFolders settings extraFlags systemService;
      guiAddress = cfg.gui.address;
    } // lib.optionalAttrs (cfg.databaseDir != null) {
      inherit (cfg) databaseDir;
    } // lib.optionalAttrs (cfg.gui.passwordFile != null) {
      guiPasswordFile = cfg.gui.passwordFile;
    } // lib.optionalAttrs (cfg.identity.keyFile != null) {
      key = cfg.identity.keyFile;
      cert = cfg.identity.certFile;
    } // lib.optionalAttrs cfg.relay.enable {
      relay = { enable = true; } // cfg.relay.options;
    };

    networking.firewall.allowedTCPPorts =
      lib.optionals cfg.gui.openFirewall [ cfg.gui.firewallPort ];
  };
}
