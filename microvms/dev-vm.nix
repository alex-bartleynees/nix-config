{ inputs }:
let
  inherit (inputs) nixpkgs;
  self = inputs.self;
  lib = nixpkgs.lib;

  username = "alexbn";
  hostName = "dev-vm";

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
  additionalUserProfiles = { alexbn.profiles = [ "agent-tools" ]; };
  extraShares = [
    {
      proto = "virtiofs";
      tag = "workspaces";
      source = "/home/${username}/workspaces";
      mountPoint = "/home/${username}/workspaces";
    }
    {
      proto = "virtiofs";
      tag = "documents";
      source = "/home/${username}/Documents";
      mountPoint = "/home/${username}/Documents";
    }
  ];
  extraModules = [
    ({ pkgs, ... }: {
      system.stateVersion = "25.05";
      nixpkgs.config.allowUnfree = true;
      myConfig = {
        inherit theme;
        desktop = "none";
        monitors = [ ];
        systemProfiles = [ ];
      };

      services.vscode-server.enable = true;

      systemd.services.t3 = {
        description = "t3 server";
        after = [ "network.target" "home-alexbn.mount" ];
        requires = [ "home-alexbn.mount" ];
        wantedBy = [ "multi-user.target" ];
        path = with pkgs; [ git gh openssh ];
        environment = { SHELL = "${pkgs.bash}/bin/bash"; };
        serviceConfig = {
          ExecStart = "${pkgs.t3code}/bin/t3 serve --host 0.0.0.0";
          User = username;
          Restart = "on-failure";
        };
      };
      systemd.tmpfiles.rules = [ "z /home/alexbn 0755 alexbn users - -" ];

      systemd.services.systemd-tmpfiles-setup = {
        after = [ "home-alexbn.mount" ];
        requires = [ "home-alexbn.mount" ];
      };

      networking.firewall.allowedTCPPorts = [
        # node/vite/react/webpack dev servers
        3000
        4200
        5173
        8080
        4000
        5000
        5001
        8000
        8081
        6006
        35729
        3773
      ];

      users.users.${username}.uid = 1000;

      sops = {
        defaultSopsFile = "${self}/secrets/secrets.yaml";
        age.keyFile = lib.mkForce "/var/lib/sops-nix/age-key.txt";
        secrets."passwords/${username}" = {
          neededForUsers = true;
          mode = "0400";
          owner = "root";
        };
      };

      home-manager.users.${username} = {
        claude-code.enableSandbox = lib.mkForce false;
        opencode.enableSandbox = lib.mkForce false;
        shell.enableAtuin = lib.mkForce false;
      };
    })
  ];
}
