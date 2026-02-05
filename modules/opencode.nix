# homeModule: true
{ config, lib, pkgs, ... }:
let cfg = config.opencode;
in {
  options.opencode = {
    enable = lib.mkEnableOption "OpenCode AI assistant";

    enableSandbox = lib.mkOption {
      type = lib.types.bool;
      default = pkgs.stdenv.isLinux;
      description = "Enable landrun sandbox for OpenCode (Linux only).";
    };

    workspaceDirs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default =
        [ "$HOME/workspaces" "$HOME/.config/nix-config" "$HOME/Documents" ];
      description = "Directories to grant read-write-execute access to.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      # OpenCode wrapper - sandboxed or direct based on config
      (pkgs.writeShellScriptBin "opencode"
        (if cfg.enableSandbox && pkgs.stdenv.isLinux then ''
          # Create config directories if they don't exist
          mkdir -p "$HOME/.config/opencode"
          mkdir -p "$HOME/.cache/opencode"
          mkdir -p "$HOME/.local/share/opencode/log"
          mkdir -p "$HOME/.local/state/opencode"
          touch "$HOME/.gitconfig"

          # Create workspace directories if they don't exist
          ${lib.concatMapStringsSep "\n" (dir: ''mkdir -p "${dir}"'')
          (builtins.filter (d: !(lib.hasPrefix "$HOME" d)) cfg.workspaceDirs)}

          # Run opencode with landrun sandbox
          exec ${pkgs.landrun}/bin/landrun \
            --best-effort \
            --rox /nix/store,/usr,/run/current-system \
            --ro /dev,/etc,/sys,/proc \
            --rw /dev/null,/dev/stdin,/dev/stdout,/dev/stderr,/dev/tty \
            --ro "$HOME/.gitconfig" \
            --rw "$HOME/.config/opencode,$HOME/.cache/opencode,$HOME/.local/share/opencode,$HOME/.local/state/opencode" \
            ${
              lib.concatMapStringsSep " " (dir: ''--rwx "${dir}"'')
              cfg.workspaceDirs
            } \
            --rwx /tmp \
            --connect-tcp 443 \
            --env HOME \
            --env PATH \
            --env XDG_CONFIG_HOME \
            --env XDG_CACHE_HOME \
            --env XDG_STATE_HOME \
            --env USER \
            --env TERM \
            --env LANG \
            --env LC_ALL \
            -- \
            ${pkgs.opencode}/bin/opencode "$@"
        '' else ''
          # Run opencode directly without sandboxing
          exec ${pkgs.opencode}/bin/opencode "$@"
        ''))
    ];
  };
}
