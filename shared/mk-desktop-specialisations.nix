{ inputs, lib }:
{ baseImports, theme, username, homeDirectory, desktops ? [ ] }:
let
  mkDesktopSpecialisation = desktop:
    let
      shared = import ./nixos-default.nix {
        inherit inputs theme username homeDirectory desktop lib;
      };
      sharedImports = shared.getImports {
        additionalImports = baseImports ++ [{ _module.args.theme = theme; }];
      };
    in {
      inheritParentConfig = false;
      configuration = {
        imports = sharedImports ++ [ ../core/desktops/${desktop}.nix ];
      };
    };

in { specialisation = lib.genAttrs desktops mkDesktopSpecialisation; }

