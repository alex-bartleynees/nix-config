{ pkgs, inputs, theme, lib, ... }: {
  services.dunst = {
    enable = true;
    settings = {
      global = {
        frame_color = lib.mkForce theme.themeColors.active_border;
        separator_color = lib.mkForce "frame";
      };
      urgency_low = {
        background = lib.mkForce theme.themeColors.groupbar_inactive;
        foreground = lib.mkForce theme.themeColors.text;
        frame_color = lib.mkForce theme.themeColors.active_border;
      };
      urgency_normal = {
        background = lib.mkForce theme.themeColors.groupbar_inactive;
        foreground = lib.mkForce theme.themeColors.text;
        frame_color = lib.mkForce theme.themeColors.active_border;
      };
      urgency_critical = {
        background = lib.mkForce theme.themeColors.groupbar_inactive;
        foreground = lib.mkForce theme.themeColors.text;
        frame_color = lib.mkForce theme.themeColors.locked_active;
      };
    };
  };
}
