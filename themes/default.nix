{ inputs, lib, self, users, additionalUserProfiles ? [ ], monitors ? [ ], ... }:
let
  # Get all theme files in this directory
  themeFiles = builtins.attrNames (lib.filterAttrs (name: type:
    type == "regular" && lib.hasSuffix ".nix" name && name != "default.nix")
    (builtins.readDir ./.));

  # Import all themes
  themes = lib.genAttrs (map (f: lib.removeSuffix ".nix" f) themeFiles) (name:
    import ./${name + ".nix"} {
      inherit inputs;
      pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
    });

  paths = import "${self}/paths.nix" self;
  moduleUtils = import "${paths.shared}/module-utils.nix" { inherit lib self; };

  # Generate specializations for each theme
  generateThemeSpecialisations = baseImports: desktop:
    lib.genAttrs (builtins.attrNames themes) (themeName:
      let
        shared = import "${paths.shared}/nixos-default.nix" {
          inherit inputs self desktop users lib additionalUserProfiles monitors;
          theme = themes.${themeName};
        };
        baseConfig = shared.getImports {
          additionalImports = baseImports
            ++ [{ _module.args.theme = themes.${themeName}; }];
        };
      in {
        inheritParentConfig = false;
        configuration = {
          imports = baseConfig ++ [ (moduleUtils.extractSystemConfig desktop) ];
        };
      });

in {
  inherit themes;
  inherit generateThemeSpecialisations;

  # Helper function to create theme specializations for a host
  mkThemeSpecialisations = { baseImports, desktop ? "hyprland", }: {
    specialisation = generateThemeSpecialisations baseImports desktop;
  };
}
