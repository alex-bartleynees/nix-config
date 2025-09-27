{ inputs, lib, username, homeDirectory, ... }:
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

  # Generate specializations for each theme
  generateThemeSpecialisations = baseImports: desktop:
    lib.genAttrs (builtins.attrNames themes) (themeName:
      let
        shared = import ../../shared/nixos-default.nix {
          inherit inputs desktop username homeDirectory lib;
          theme = themes.${themeName};
        };
        baseConfig = shared.getImports {
          additionalImports = baseImports
            ++ [{ _module.args.theme = themes.${themeName}; }];
        };
      in {
        inheritParentConfig = false;
        configuration = {
          imports = baseConfig ++ [ ../desktops/${desktop}.nix ];
        };
      });

in {
  inherit themes;
  inherit generateThemeSpecialisations;

  # Helper function to create theme specializations for a host
  mkThemeSpecialisations = { baseImports, desktop ? "hyprland" }: {
    specialisation = generateThemeSpecialisations baseImports desktop;
  };
}
