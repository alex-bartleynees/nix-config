{ config, lib, theme, username, ... }:
lib.mkIf config.profiles.linux-desktop {
  # Inherit base profile
  profiles.base = true;

  # Theming configuration
  stylixTheming = {
    enable = true;
    image = theme.wallpaper;
    base16Scheme = theme.base16Scheme;
  };

  # Common desktop services
  sambaClient.enable = true;
  silentBoot.enable = true;
  zswap.enable = true;
  snapshots.enable = true;

  # Impermanence configuration for BTRFS
  impermanence = {
    enable = true;
    subvolumes = {
      "@" = { mountpoint = "/"; };
      "@home" = { mountpoint = "/home"; };
    };
    persistPaths = config.myUsers.${username}.persistPaths;
    resetSubvolumes = [ ];
  };
}