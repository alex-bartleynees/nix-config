{ lib }:
let
  # Check if a file has the homeModule magic comment in the first 5 lines
  hasHomeMarker = path:
    let
      content = builtins.readFile path;
      lines = lib.splitString "\n" content;
      firstLines = lib.take 5 lines;
    in lib.any (line: lib.hasInfix "# homeModule: true" line) firstLines;

  # Check if a file is a combined module (has both system and home attributes)
  isCombinedModule = path:
    let content = builtins.readFile path;
    in (lib.hasInfix "system =" content || lib.hasInfix "system=" content)
    && (lib.hasInfix "home =" content || lib.hasInfix "home=" content);

  # Check if a file should be treated as a home module
  isHomeModule = path: name: hasHomeMarker path;

  # Extract system attribute from combined module
  extractSystemAttr = path:
    let module = import path;
    in if builtins.isAttrs module && module ? system then
      module.system
    else
      module;

  # Extract home attribute from combined module
  extractHomeAttr = path:
    let module = import path;
    in if builtins.isAttrs module && module ? home then module.home else module;

in {
  importAllNixFiles = dir:
    if builtins.pathExists dir then
      let
        entries = builtins.readDir dir;
        nixFiles = lib.filterAttrs (name: type:
          let path = dir + "/${name}";
          in type == "regular" && lib.hasSuffix ".nix" name && name
          != "default.nix" && !lib.hasPrefix "_" name
          && !isHomeModule path name) entries;

        regularFiles =
          map (name: dir + "/${name}") (builtins.attrNames nixFiles);

        # Also check for combined modules and extract their system attribute
        combinedModules = lib.filter (path: isCombinedModule path) regularFiles;
        combinedSystemModules =
          map (path: extractSystemAttr path) combinedModules;

        # Regular system modules (not combined)
        regularSystemModules =
          lib.filter (path: !isCombinedModule path) regularFiles;
      in regularSystemModules ++ combinedSystemModules
    else
      [ ];

  importHomeFiles = dir:
    if builtins.pathExists dir then
      let
        entries = builtins.readDir dir;
        allNixFiles = lib.filterAttrs (name: type:
          type == "regular" && lib.hasSuffix ".nix" name
          && !lib.hasPrefix "_" name && name != "default.nix") entries;

        allFilePaths =
          map (name: dir + "/${name}") (builtins.attrNames allNixFiles);

        # Filter to home modules (magic comment or hm- prefix)
        homeModulePaths = lib.filter
          (path: let name = baseNameOf path; in isHomeModule path name)
          allFilePaths;

        # Also check all regular files for combined modules
        regularFiles = lib.filter
          (path: let name = baseNameOf path; in !isHomeModule path name)
          allFilePaths;

        combinedModules = lib.filter (path: isCombinedModule path) regularFiles;
        combinedHomeModules = map (path: extractHomeAttr path) combinedModules;

      in homeModulePaths ++ combinedHomeModules
    else
      [ ];
}
