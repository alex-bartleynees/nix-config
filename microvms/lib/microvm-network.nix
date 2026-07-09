{ lib }:
vmNames:
lib.listToAttrs (lib.imap0 (i: name: {
  inherit name;
  value = {
    tapId = "vm-${name}";
    mac = "02:00:00:00:00:${lib.toHexString (i + 1)}";
    ipAddress = "10.0.${toString i}.2";
    gateway = "10.0.${toString i}.1";
  };
}) vmNames)
