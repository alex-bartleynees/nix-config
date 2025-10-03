{ lib }: {
  importAllNixFiles = dir:
    if builtins.pathExists dir then
      let
        entries = builtins.readDir dir;
        nixFiles = lib.filterAttrs (name: type:
          type == "regular" && lib.hasSuffix ".nix" name && name
          != "default.nix" && !lib.hasPrefix "_" name
          && !lib.hasPrefix "hm-" name) entries;
      in map (name: dir + "/${name}") (builtins.attrNames nixFiles)
    else
      [ ];

  importHomeFiles = dir:
    if builtins.pathExists dir then
      let
        entries = builtins.readDir dir;
        homeFiles = lib.filterAttrs (name: type:
          type == "regular" && lib.hasSuffix ".nix" name
          && lib.hasPrefix "hm-" name) entries;
      in map (name: dir + "/${name}") (builtins.attrNames homeFiles)
    else
      [ ];
}
