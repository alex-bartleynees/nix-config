{ inputs, lib }:
({ baseImports, theme, users, desktops ? [ ], additionalUserProfiles ? [ ]
  , monitors ? [ ], }:
  let
    extractors = import ./module-extractors.nix;

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
            ++ [ (extractors.extractSystemConfig desktop) ];
        };
      };

  in { specialisation = lib.genAttrs desktops mkDesktopSpecialisation; })
