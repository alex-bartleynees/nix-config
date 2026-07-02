{ inputs, lib }:
({ baseImports, theme, users, desktops ? [ ], additionalUserProfiles ? [ ]
  , monitors ? [ ], }:
  let
    moduleUtils = import ./module-utils.nix { inherit lib; };

    mkDesktopSpecialisation = desktop:
      let
        shared = import ./nixos-default.nix {
          inherit inputs theme users desktop lib additionalUserProfiles
            monitors;
        };
        sharedImports = shared.getImports {
          additionalImports = baseImports ++ [{ _module.args.theme = theme; }];
        };
      in {
        inheritParentConfig = false;
        configuration = {
          imports = sharedImports
            ++ [ (moduleUtils.extractSystemConfig desktop) ];
        };
      };

  in { specialisation = lib.genAttrs desktops mkDesktopSpecialisation; })
