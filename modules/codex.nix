{
  homeConfig = { config, lib, pkgs, ... }:
    let cfg = config.codex;
    in {
      options.codex = {
        enable = lib.mkEnableOption "Codex AI assistant";

        enableSandbox = lib.mkOption {
          type = lib.types.bool;
          default = pkgs.stdenv.isLinux;
          description = "Enable landrun sandbox for Codex (Linux only).";
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
          # Unrestricted login helper - the OAuth flow binds a local
          # callback server, which the landrun sandbox blocks.
          (pkgs.writeShellScriptBin "codex-login" ''
            exec ${pkgs.codex}/bin/codex login "$@"
          '')

          # Codex wrapper - sandboxed or direct based on config
          (pkgs.writeShellScriptBin "codex"
            (if cfg.enableSandbox && pkgs.stdenv.isLinux then ''
              # Create config directories if they don't exist
              mkdir -p "$HOME/.codex"
              mkdir -p "$HOME/.t3"
              touch "$HOME/.gitconfig"

              # Create workspace directories if they don't exist
              ${lib.concatMapStringsSep "\n" (dir: ''mkdir -p "${dir}"'')
              (builtins.filter (d: !(lib.hasPrefix "$HOME" d))
                cfg.workspaceDirs)}

              DEV_RW="/dev/null,/dev/tty"
              [ -t 0 ] && DEV_RW="$DEV_RW,/dev/stdin"
              [ -t 1 ] && DEV_RW="$DEV_RW,/dev/stdout"
              [ -t 2 ] && DEV_RW="$DEV_RW,/dev/stderr"

              # Run codex with landrun sandbox
              # HERDR_AGENT tells herdr which agent this is, since landrun
              # hides the real codex process from host /proc.
              exec env HERDR_AGENT=codex ${pkgs.landrun}/bin/landrun \
                --best-effort \
                --rox /nix/store,/usr,/run/current-system \
                --ro /dev,/etc,/sys,/proc \
                --rw "$DEV_RW" \
                --ro "$HOME/.gitconfig" \
                --rw "$HOME/.codex,$HOME/.t3" \
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
                ${pkgs.codex}/bin/codex "$@"
            '' else ''
              # Run codex directly without sandboxing
              exec ${pkgs.codex}/bin/codex "$@"
            ''))
        ];
      };
    };
}
