{ pkgs, ... }: {
  # Install mergerfs package
  environment.systemPackages = with pkgs; [ mergerfs ];

  # Configure file systems for media drives and mergerfs pool
  fileSystems = {
    # First media drive
    "/mnt/media" = {
      device = "/dev/disk/by-uuid/498b6b54-98a0-41f0-85d8-5741cb79b303";
      fsType = "ext4";
      options = [ "defaults" ];
    };

    # Second media drive  
    "/mnt/media2" = {
      device = "/dev/disk/by-uuid/d74c8238-4030-4924-b4b1-0be0fd406187";
      fsType = "ext4";
      options = [ "defaults" "noatime" ];
    };

    # MergerFS pool combining both drives
    "/mnt/jellyfin-pool" = {
      device = "/mnt/media:/mnt/media2";
      fsType = "fuse.mergerfs";
      options = [
        "defaults"
        "rw"
        "uid=1000"
        "gid=1000"
        "default_permissions"
        "allow_other"
        "use_ino"
        "cache.files=partial"
        "dropcacheonclose=true"
        "category.create=mfs"
      ];
      depends = [ "/mnt/media" "/mnt/media2" ];
    };
  };

  # Ensure mergerfs pool mounts after individual drives
  systemd.services."mnt-jellyfin\\x2dpool" = {
    after = [ "mnt-media.mount" "mnt-media2.mount" ];
    requires = [ "mnt-media.mount" "mnt-media2.mount" ];
  };

  # Create mount points and media directories with proper permissions
  systemd.tmpfiles.rules = [
    # Create mount points
    "d /mnt/media 0755 root root - -"
    "d /mnt/media2 0755 root root - -"
    "d /mnt/jellyfin-pool 0755 root root - -"

    # Create media subdirectories after mount
    "d /mnt/jellyfin-pool/books 0775 1000 1000 - -"
    "d /mnt/jellyfin-pool/documents 0775 1000 1000 - -"
    "d /mnt/jellyfin-pool/photos 0775 1000 1000 - -"
    "d /mnt/jellyfin-pool/movies 0775 1000 1000 - -"
    "d /mnt/jellyfin-pool/tv 0775 1000 1000 - -"
    "d /mnt/jellyfin-pool/music 0775 1000 1000 - -"
  ];

  # Ensure directories are created after the mount point exists
  systemd.services.systemd-tmpfiles-setup.after =
    [ "mnt-jellyfin\\x2dpool.mount" ];
}
