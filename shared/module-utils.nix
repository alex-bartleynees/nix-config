{ lib }:
let
  extractAttr = path:
    let module = import path;
    in if builtins.isAttrs module then module else null;

  scanDir = dir:
    if builtins.pathExists dir then
      let
        entries = builtins.readDir dir;
        nixFiles = lib.filterAttrs (name: type:
          type == "regular" && lib.hasSuffix ".nix" name
          && name != "default.nix" && !lib.hasPrefix "_" name) entries;
      in map (name: dir + "/${name}") (builtins.attrNames nixFiles)
    else
      [ ];

in {
  # Extract nixosConfig from a desktop module by name.
  # Falls back to the whole module for plain NixOS desktop modules.
  extractSystemConfig = desktop:
    let module = import (../desktops + "/${desktop}.nix");
    in if builtins.isAttrs module && module ? nixosConfig then
      module.nixosConfig
    else
      module;

  # Extract homeConfig from a desktop module by name.
  # Returns an empty module when the desktop has no homeConfig.
  extractHomeConfig = desktop:
    let module = import (../desktops + "/${desktop}.nix");
    in if builtins.isAttrs module && module ? homeConfig then
      module.homeConfig
    else
      { ... }: { };

  # Return all NixOS modules from a directory.
  # Handles both { nixosConfig = ...; } bundles and plain module functions.
  # Skips files that only have homeConfig.
  importAllNixFiles = dir:
    lib.concatMap (path:
      let attrs = extractAttr path;
      in if attrs != null && attrs ? nixosConfig then
        [ attrs.nixosConfig ]
      else if attrs != null && attrs ? homeConfig then
        [ ]
      else
        [ path ]) (scanDir dir);

  # Return all home-manager modules from a directory.
  # Only picks up files that have a homeConfig attribute.
  importHomeFiles = dir:
    lib.concatMap (path:
      let attrs = extractAttr path;
      in if attrs != null && attrs ? homeConfig then
        [ attrs.homeConfig ]
      else
        [ ]) (scanDir dir);
}
