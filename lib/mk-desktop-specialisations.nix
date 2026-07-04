{ inputs, lib, self }:
({ baseImports, users, desktops ? [ ], additionalUserProfiles ? { }, hostConfig
  }:
  let
    moduleUtils = import ./module-utils.nix { inherit lib self; };

    mkDesktopSpecialisation = desktop:
      let
        shared = import ./system-base.nix {
          inherit inputs self users lib additionalUserProfiles;
          hostConfig = hostConfig // { inherit desktop; };
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
