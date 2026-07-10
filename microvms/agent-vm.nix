{ inputs }:
let
  inherit (inputs) nixpkgs;
  self = inputs.self;
  lib = nixpkgs.lib;

  username = "netclaw";
  hostName = "agent-vm";

  paths = import "${self}/paths.nix" self;

  vmNames = import "${paths.microvmsLib}/microvm-vms.nix";
  vmNetwork =
    (import "${paths.microvmsLib}/microvm-network.nix" { inherit lib; }
      vmNames).${hostName};

  pkgs = import nixpkgs {
    system = "x86_64-linux";
    config.allowUnfree = true;
  };
  theme = import "${paths.themes}/tokyo-night.nix" { inherit inputs pkgs; };

  mkMicrovmSystem = import ./lib/mk-microvm-system.nix { inherit inputs; };
in mkMicrovmSystem {
  inherit hostName;
  inherit (vmNetwork) ipAddress tapId mac gateway;
  inherit username;
  homeDirectory = "/home/${username}";
  homeVolumeSize = 16384;
  extraShares = [
    {
      proto = "virtiofs";
      tag = "agent-vm-share";
      source = "/home/alexbn/agent-vm-share";
      mountPoint = "/home/${username}/share";
    }
  ];
  extraModules = [
    ({ config, lib, pkgs, ... }: {
      system.stateVersion = "25.05";
      environment.systemPackages =
        [ inputs.netclaw.packages.${pkgs.stdenv.hostPlatform.system}.netclaw ];
      myConfig = {
        inherit theme;
        desktop = "none";
        monitors = [ ];
        systemProfiles = [ ];
      };

      home-manager.users.${username} = { lib, osConfig, ... }: {
        shell = {
          enable = true;
          enableAtuin = lib.mkForce false;
        };

        systemd.user.services.netclawd = {
          Unit = { Description = "netclaw daemon"; After = [ "network.target" ]; };
          Service = {
            ExecStart =
              "${inputs.netclaw.packages.${pkgs.stdenv.hostPlatform.system}.netclaw}/bin/netclawd";
            Restart = "on-failure";
            RestartSec = 5;
            EnvironmentFile = osConfig.sops.templates.netclaw-env.path;
          };
          Install.WantedBy = [ "default.target" ];
        };

        home.activation.seedNetclawConfig =
          lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            if [ ! -e "$HOME/.netclaw/config/netclaw.json" ]; then
              mkdir -p "$HOME/.netclaw/config"
              echo '{"configVersion":1}' > "$HOME/.netclaw/config/netclaw.json"
            fi
          '';
      };

      services.tailscale = {
        authKeyFile = config.sops.secrets."netclaw/tailscale-authkey".path;
        serve = {
          enable = true;
          services.netclawd.endpoints."tcp:443" = "http://127.0.0.1:5199";
        };
      };

      systemd.tmpfiles.rules = [ "z /home/netclaw 0755 netclaw users - -" ];
      systemd.services.systemd-tmpfiles-setup = {
        after = [ "home-netclaw.mount" ];
        requires = [ "home-netclaw.mount" ];
      };

      systemd.services.netclaw-age-key-bootstrap = {
        description = "Generate agent-vm sops age key if missing";
        wantedBy = [ "multi-user.target" ];
        after = [ "var.mount" ];
        requires = [ "var.mount" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          set -euo pipefail
          mkdir -p /var/lib/sops-nix
          if [ ! -f /var/lib/sops-nix/age-key.txt ]; then
            ${pkgs.age}/bin/age-keygen -o /var/lib/sops-nix/age-key.txt
          fi
          ${pkgs.age}/bin/age-keygen -y /var/lib/sops-nix/age-key.txt \
            > /var/lib/sops-nix/age-key.pub
          chmod 644 /var/lib/sops-nix/age-key.pub
        '';
      };

      sops = {
        defaultSopsFile = "${self}/secrets/secrets.yaml";
        age.keyFile = lib.mkForce "/var/lib/sops-nix/age-key.txt";
        secrets."netclaw/openai-api-key" = { };
        secrets."netclaw/tailscale-authkey" = { };
        templates."netclaw-env" = {
          owner = username;
          content = ''
            NETCLAW_Providers__openai__Type=openai
            NETCLAW_Providers__openai__ApiKey=${
              config.sops.placeholder."netclaw/openai-api-key"
            }
            NETCLAW_Models__Main__Provider=openai
            NETCLAW_Models__Main__ModelId=gpt-5.4-nano
          '';
        };
      };

      users.users.${username}.uid = 1000;
    })
  ];
}
