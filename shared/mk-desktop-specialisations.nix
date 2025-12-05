{ inputs, lib }:
({ baseImports, theme, users, desktops ? [ ], additionalUserProfiles ? [ ], }:
  let
    mkDesktopSpecialisation = desktop:
      let
        shared = import ./nixos-default.nix {
          inherit inputs theme users desktop lib additionalUserProfiles;
        };
        sharedImports = shared.getImports {
          additionalImports = baseImports ++ [{ _module.args.theme = theme; }];
        };
      in {
        inheritParentConfig = false;
        configuration = {
          imports = sharedImports ++ [ ../desktops/${desktop}.nix ];
        };
      };

  in { specialisation = lib.genAttrs desktops mkDesktopSpecialisation; })
