{ lib }: {
  importAllNixFiles = dir:
    if builtins.pathExists dir then
      let
        entries = builtins.readDir dir;
        nixFiles = lib.filterAttrs (name: type:
          type == "regular" && lib.hasSuffix ".nix" name && name
          != "default.nix") entries;
      in map (name: dir + "/${name}") (builtins.attrNames nixFiles)
    else
      [ ];
}
