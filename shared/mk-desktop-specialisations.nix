{ inputs, lib }:
({ baseImports, theme, users, desktops ? [ ], additionalUserProfiles ? [ ], }:
  let
    # Extract nixosConfig from combined module if it exists
    extractSystemConfig = desktop:
      let
        module = import ../desktops/${desktop}.nix;
      in if builtins.isAttrs module && module ? nixosConfig then
        module.nixosConfig
      else
        module;

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
          imports = sharedImports ++ [ (extractSystemConfig desktop) ];
        };
      };

  in { specialisation = lib.genAttrs desktops mkDesktopSpecialisation; })
