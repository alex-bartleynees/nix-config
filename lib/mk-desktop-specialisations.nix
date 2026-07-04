{ inputs, lib, self }:
({ baseImports, theme, users, desktops ? [ ], additionalUserProfiles ? [ ]
  , monitors ? [ ], }:
  let
    moduleUtils = import ./module-utils.nix { inherit lib self; };

    mkDesktopSpecialisation = desktop:
      let
        shared = import ./system-base.nix {
          inherit inputs self theme users desktop lib additionalUserProfiles
            monitors;
        };
        sharedImports = shared.getImports { additionalImports = baseImports; };
      in {
        inheritParentConfig = false;
        configuration = {
          imports = sharedImports
            ++ [ (moduleUtils.extractSystemConfig desktop) ];
        };
      };

  in { specialisation = lib.genAttrs desktops mkDesktopSpecialisation; })
