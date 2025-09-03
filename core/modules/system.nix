{ config, pkgs, lib, ... }:
let cfg = config.system;
in {
  options.system = {
    isWsl = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable WSL (Windows Subsystem for Linux) support";
    };
  };

  config = lib.mkMerge [
    # Common settings for both Linux and WSL
    {
      # Programs
      programs.zsh.enable = true;
      programs.dconf.enable = true;

      # DBus
      services.dbus = {
        enable = true;
        implementation = "broker";
      };

      # System wide settings
      nix = {
        settings = {
          auto-optimise-store = true;
          experimental-features = [ "nix-command" "flakes" ];
        };
        gc = {
          automatic = true;
          dates = "weekly";
          options = "--delete-older-than 30d";
        };
      };
    }

    # Linux-specific settings (not WSL)
    (lib.mkIf (!cfg.isWsl) {
      # Bootloader
      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;
      boot.loader.systemd-boot.consoleMode = "max";

      boot = { kernelPackages = pkgs.linuxKernel.packages.linux_zen; };

      # Hardware
      hardware.graphics = { enable = true; };
      hardware.bluetooth.enable = true;
      hardware.bluetooth.powerOnBoot = true;
      hardware.xpadneo.enable = true;

      # Programs
      programs.nm-applet = { enable = true; };

      # Services
      services.dbus.packages = with pkgs; [
        pkgs.gnome-keyring
        pkgs.xdg-desktop-portal
      ];
      services.blueman.enable = true;
      services.upower.enable = true;
      services.acpid.enable = true;
      services.xserver.xkb = {
        layout = "nz";
        variant = "";
      };
      services.udisks2.enable = true;
      services.gnome.gnome-keyring.enable = true;

      # Allow users in wheel group to switch specialisations without sudo
      security.sudo.extraRules = [{
        groups = [ "wheel" ];
        commands = [{
          command = "/nix/store/*/specialisation/*/bin/switch-to-configuration";
          options = [ "NOPASSWD" ];
        }];
      }];

      # Networking
      networking.nameservers = [ "8.8.8.8" "1.1.1.1" ];
      networking.networkmanager.enable = true;

      # Audio
      services.pipewire = {
        enable = true;
        pulse.enable = true;
      };

      # Root user
      users.mutableUsers = false;
      users.users.root = {
        initialHashedPassword =
          "$6$n2D1ZBpbcavgoyMs$lwoQv71z3pGUStla4XV7jWGJnFEfU16aODX0F1JbhuUrvqn1JsjEQ7QMKB8qvItrmH5R0qEax/AIOAygpJdRW.";
        hashedPasswordFile = config.sops.secrets."passwords/root".path;
      };
    })

    # WSL-specific settings
    (lib.mkIf cfg.isWsl {
      # Programs
      programs.nix-ld = {
        enable = true;
        package = pkgs.nix-ld-rs;
      };

      # Services
      services = { openssh.enable = true; };

      # WSL-specific packages
      environment.systemPackages = with pkgs; [
        adwaita-qt
        gtk-engine-murrine
        gtk_engines
        gsettings-desktop-schemas
        adwaita-icon-theme
        openssl
        zlib
        stdenv.cc.cc.lib
      ];

      # Qt theming for WSL
      qt = {
        enable = true;
        platformTheme = "gnome";
        style = "adwaita-dark";
      };

      # VSCode remote workaround
      systemd.user = {
        paths.vscode-remote-workaround = {
          wantedBy = [ "default.target" ];
          pathConfig.PathChanged = "%h/.vscode-server/bin";
        };
        services.vscode-remote-workaround.script = ''
          for i in ~/.vscode-server/bin/*; do
            if [ -e $i/node ]; then
              echo "Fixing vscode-server in $i..."
              ln -sf ${pkgs.nodejs_22}/bin/node $i/node
            fi
          done
        '';
      };
    })
  ];
}
