{ pkgs, ... }: {
  imports =
    [ ../../modules/vscode ../../modules/rider ../../modules/linux-packages ];
  home.packages = with pkgs; [ kanshi ];

  services.kanshi = {
    enable = true;
    systemdTarget = "river-session.target";

    profiles = {
      # ThinkPad + External LG UltraGear display
      docked = {
        outputs = [
          {
            criteria = "eDP-1"; # eDP-1 (laptop)
            mode = "1920x1080@60";
            position = "0,1440";
            status = "enable";
          }
          {
            criteria = "DP-1"; # DP-1 (external)
            mode = "2560x1440@60";
            position = "0,0";
            status = "enable";
          }
        ];
      };
    };
  };
}
