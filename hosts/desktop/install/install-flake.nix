{
  description = "NixOS installation configuration with disko";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Import your main flake inputs for consistency
    nixos-config = {
      url = "path:../../.."; # Points to your main flake.nix
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, disko, nixos-config, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      nixosConfigurations.installer = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          disko.nixosModules.disko
          ./disko-config.nix
          {
            # Minimal installer configuration
            boot.loader.systemd-boot.enable = true;
            boot.loader.efi.canTouchEfiVariables = true;

            # Enable SSH for remote installation
            services.openssh.enable = true;
            services.openssh.settings.PermitRootLogin = "yes";
            users.users.root.openssh.authorizedKeys.keys = [
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFKxSGAbg6Dw8DqxiPGikz9ZoXDBI6YvV80L5B1NsQ72 alexbartleynees@gmail.com"
            ];

            # Basic networking
            networking.dhcpcd.enable = true;
            networking.wireless.enable =
              false; # Use NetworkManager instead if needed

            # Essential packages for installation
            environment.systemPackages = with pkgs; [ git vim curl wget ];

            # Enable flakes
            nix.settings.experimental-features = [ "nix-command" "flakes" ];
          }
        ];
      };

      # Installation script
      packages.${system}.install-script =
        pkgs.writeShellScriptBin "install-nixos" ''
          set -e

          echo "Starting NixOS installation with LUKS encryption and disko..."

          # Check if LUKS key file exists, create if needed
          if [ ! -f /tmp/secret.key ]; then
            echo "LUKS key file not found. Creating encryption key..."
            echo "Enter LUKS encryption password (will be saved to /tmp/secret.key):"
            read -s luks_password
            echo "$luks_password" > /tmp/secret.key
            chmod 600 /tmp/secret.key
            echo "LUKS key file created at /tmp/secret.key"
          else
            echo "Using existing LUKS key file at /tmp/secret.key"
          fi

          # Format and partition the disk (will prompt for LUKS password)
          echo "Partitioning disk with LUKS encryption..."
          sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko -- --mode disko ./disko-config.nix

          # Generate hardware configuration
          echo "Generating hardware configuration..."
          sudo nixos-generate-config --root /mnt --show-hardware-config > /tmp/hardware-configuration.nix

          echo "Disk partitioning complete. Hardware configuration generated."
          echo ""
          echo "IMPORTANT: Your root partition is now encrypted with LUKS!"
          echo "Device: /dev/nvme1n1p3 -> /dev/mapper/crypted"
          echo ""
          echo "Next steps:"
          echo "1. Copy your main flake configuration to /mnt/etc/nixos/"
          echo "2. Update hardware-configuration.nix with LUKS configuration:"
          echo "   boot.initrd.luks.devices.\"crypted\" = {"
          echo "     device = \"/dev/nvme1n1p3\";"
          echo "     preLVM = true;"
          echo "   };"
          echo "3. Run: sudo nixos-install --flake /mnt/etc/nixos#desktop"
          echo "4. During installation, you'll be prompted for the LUKS password again"
          echo ""
          echo "Remember: You'll need to enter the LUKS password at every boot!"
        '';
    };
}
