{ inputs }:
let
  inherit (inputs) nixpkgs;
  self = inputs.self;
  lib = nixpkgs.lib;

  username = "alexbn";
  hostName = "wiki-vm";

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

  # The media host's Syncthing copy of the vault (see profiles/media-server.nix).
  hostVault = "/home/${username}/projects/obsidian-vault";
  vault = "/home/${username}/Documents/obsidian-vault";
  port = 4320;

  mkMicrovmSystem = import ./lib/mk-microvm-system.nix { inherit inputs; };
in mkMicrovmSystem {
  inherit hostName;
  inherit (vmNetwork) ipAddress tapId mac gateway;
  inherit username;
  mem = 4096;
  vcpu = 4;
  homeVolumeSize = 16384;
  additionalUserProfiles = { alexbn.profiles = [ "agent-tools" ]; };
  extraShares = [{
    proto = "virtiofs";
    tag = "obsidian-vault";
    source = hostVault;
    mountPoint = vault;
  }];
  extraModules = [
    ({ config, pkgs, ... }: {
      system.stateVersion = "25.05";
      nixpkgs.config.allowUnfree = true;

      myConfig = {
        inherit theme;
        desktop = "none";
        monitors = [ ];
        systemProfiles = [ ];
      };

      # Reached only through Tailscale Serve; wiki-agents has no login, so it
      # listens on loopback and the tailnet ACLs are the access boundary.
      services.tailscale = {
        authKeyFile = config.sops.secrets."wiki-vm/tailscale-authkey".path;
        serve = {
          enable = true;
          services.wiki-agents.endpoints."tcp:443" =
            "http://127.0.0.1:${toString port}";
        };
      };

      # Same uid as the host user so the virtiofs vault share is writable.
      users.users.${username}.uid = 1000;

      systemd.tmpfiles.rules = [ "z /home/${username} 0755 ${username} users - -" ];
      systemd.services.systemd-tmpfiles-setup = {
        after = [ "home-${username}.mount" ];
        requires = [ "home-${username}.mount" ];
      };

      # Generate the VM's sops age key on first boot; only the public key is
      # left world-readable for adding to .sops.yaml.
      systemd.services.wiki-vm-age-key-bootstrap = {
        description = "Generate wiki-vm sops age key if missing";
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
          if [ ! -s /var/lib/sops-nix/age-key.txt ]; then
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
        secrets."passwords/${username}" = {
          neededForUsers = true;
          mode = "0400";
          owner = "root";
        };
        secrets."wiki-vm/tailscale-authkey" = { };
      };

      home-manager.users.${username} = {
        claude-code.enableSandbox = lib.mkForce false;
        opencode.enableSandbox = lib.mkForce false;
        codex.enableSandbox = lib.mkForce false;
        shell.enableAtuin = lib.mkForce false;

        services.wiki-agents = {
          enable = true;
          # Start at boot without anyone logging in.
          enableLinger = true;
          vaults = [ vault ];
          host = "127.0.0.1"; # exposed via Tailscale Serve
          inherit port;
          watchPollMs = 2000; # virtiofs doesn't report host-side changes
        };
      };
    })
  ];
}
