{ lib, monitors, ... }:
let
  primaryMonitor = builtins.head (builtins.filter (m: m.primary) monitors);
in {
  services.kanshi = {
    enable = true;
    systemdTarget = "niri-session.target";

    settings = [{
      profile = {
        name = "docked";
        outputs = [
          {
            criteria = primaryMonitor.name;
            mode = "${toString primaryMonitor.width}x${toString primaryMonitor.height}@${toString (builtins.floor primaryMonitor.refresh)}";
            position = "0,1440";
            status = "enable";
          }
          {
            criteria = "DP-1";
            mode = "2560x1440@60";
            position = "0,0";
            status = "enable";
          }
        ];
      };
    }];
  };
}
