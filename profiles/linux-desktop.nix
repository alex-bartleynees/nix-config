{ config, lib, theme, users, ... }:
let
  allUserPersistPaths = lib.flatten
    (lib.mapAttrsToList (username: userConfig: userConfig.persistPaths or [ ])
      config.myUsers);
  rootPaths = import ../shared/root-persistence.nix { };
in lib.mkIf config.profiles.linux-desktop {
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
    persistPaths = rootPaths.rootPersistPaths ++ allUserPersistPaths;
    resetSubvolumes = [ ];
  };
}
