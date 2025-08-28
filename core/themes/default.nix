{ inputs, lib, ... }:
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
  generateThemeSpecialisations = baseConfig: desktop:
    lib.genAttrs (builtins.attrNames themes) (themeName: {
      inheritParentConfig = false;
      configuration = {
        imports = baseConfig ++ [ ../desktops/${desktop}.nix ];
        # Override theme in specialization
        _module.args.theme = themes.${themeName};
      };
    });

in {
  inherit themes;
  inherit generateThemeSpecialisations;

  # Helper function to create theme specializations for a host
  mkThemeSpecialisations = { baseConfig, desktop ? "hypr" }: {
    specialisation = generateThemeSpecialisations baseConfig desktop;
  };
}
