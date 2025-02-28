{ config, lib, pkgs, inputs, ... }:
let shared = import ../../../shared/nixos-default.nix { inherit inputs; };
in {
  nix.settings = {
    substituters = [ "https://cosmic.cachix.org/" ];
    trusted-public-keys =
      [ "cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE=" ];
  };

  imports = shared.getImports {
    additionalImports = [ inputs.nixos-cosmic.nixosModules.default ];
  };

  services.desktopManager.cosmic.enable = true;
  services.displayManager.cosmic-greeter.enable = true;

}
