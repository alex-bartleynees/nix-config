{ lib, monitors, ... }:
let
  toKanshiOutput = m: {
    criteria = m.description;
    mode = "${toString m.width}x${toString m.height}@${toString (builtins.floor m.refresh)}";
    position = "${toString m.x},${toString m.y}";
    status = "enable";
  } // lib.optionalAttrs (m.transform != 0) { transform = toString m.transform; };
in {
  services.kanshi = {
    enable = true;
    settings = [
      {
        profile = {
          name = "coding";
          outputs = map toKanshiOutput monitors;
        };
      }
      {
        profile = {
          name = "gaming";
          outputs = map (m:
            (toKanshiOutput m) // lib.optionalAttrs (!m.primary) { status = "disable"; }
          ) monitors;
        };
      }
    ];
  };
}
