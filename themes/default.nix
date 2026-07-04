{ inputs, lib, self, users, additionalUserProfiles ? { }, hostConfig }:
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
  moduleUtils = import "${paths.lib}/module-utils.nix" { inherit lib self; };

  # Generate specializations for each theme
  generateThemeSpecialisations = baseImports:
    lib.genAttrs (builtins.attrNames themes) (themeName:
      let
        shared = import "${paths.lib}/system-base.nix" {
          inherit inputs self users lib additionalUserProfiles;
          hostConfig = hostConfig // { theme = themes.${themeName}; };
        };
        baseConfig = shared.getImports { additionalImports = baseImports; };
      in {
        inheritParentConfig = false;
        configuration = {
          imports = baseConfig
            ++ [ (moduleUtils.extractSystemConfig hostConfig.desktop) ];
        };
      });

in {
  inherit themes;
  inherit generateThemeSpecialisations;

  mkThemeSpecialisations = { baseImports }: {
    specialisation = generateThemeSpecialisations baseImports;
  };
}
