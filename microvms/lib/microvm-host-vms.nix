{ lib }:
let
  vmNames = import ./microvm-vms.nix;
  networks = import ./microvm-network.nix { inherit lib; } vmNames;
in hostVmNames:
lib.mapAttrs (name: v: {
  inherit (v) tapId gateway;
  autostart = true;
}) (lib.getAttrs hostVmNames networks)
