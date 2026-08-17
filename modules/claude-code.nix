{
  homeConfig = { config, lib, pkgs, ... }:
    let cfg = config.claude-code;
    in {
      options.claude-code = {
        enable = lib.mkEnableOption "Claude Code AI assistant";

        enableSandbox = lib.mkOption {
          type = lib.types.bool;
          default = pkgs.stdenv.hostPlatform.isLinux;
          description = "Enable landrun sandbox for Claude Code (Linux only).";
        };

        workspaceDirs = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = ''
            Extra directories to grant read-write-execute access to. Definitions
            are merged with the base workspace directories set by this module.
          '';
        };
      };

      config = lib.mkIf cfg.enable {
        claude-code.workspaceDirs =
          [ "$HOME/workspaces" "$HOME/.config/nix-config" "$HOME/Documents" ];

        home.packages = [
          # Unrestricted login helper for OAuth (not needed on macOS)
          (pkgs.writeShellScriptBin "claude-login"
            (if pkgs.stdenv.hostPlatform.isLinux then ''
              exec ${pkgs.claude-code}/bin/claude /login
            '' else ''
              exec ${pkgs.claude-code}/bin/claude "$@"
            ''))

          # Claude wrapper - sandboxed or direct based on config
          (pkgs.writeShellScriptBin "claude"
            (if cfg.enableSandbox && pkgs.stdenv.hostPlatform.isLinux then ''
              # Create config directories if they don't exist
              mkdir -p "$HOME/.config/claude-code"
              mkdir -p "$HOME/.cache/claude"
              mkdir -p "$HOME/.local/state/claude-code"
              mkdir -p "$HOME/.claude/plugins"
              mkdir -p "$HOME/.t3"

              # Global skill locations
              mkdir -p "$HOME/.claude/skills"
              mkdir -p "$HOME/.agents/skills"
              touch "$HOME/.claude.json"
              touch "$HOME/.gitconfig"

              # Create workspace directories if they don't exist
              ${lib.concatMapStringsSep "\n" (dir: ''mkdir -p "${dir}"'')
              (builtins.filter (d: !(lib.hasPrefix "$HOME" d))
                cfg.workspaceDirs)}

              DEV_RW="/dev/null,/dev/tty"
              [ -t 0 ] && DEV_RW="$DEV_RW,/dev/stdin"
              [ -t 1 ] && DEV_RW="$DEV_RW,/dev/stdout"
              [ -t 2 ] && DEV_RW="$DEV_RW,/dev/stderr"

              # Run claude with landrun sandbox
              # HERDR_AGENT tells herdr which agent this is, since landrun
              # hides the real claude process from host /proc.
              exec env HERDR_AGENT=claude ${pkgs.landrun}/bin/landrun \
                --best-effort \
                --rox /nix/store,/usr,/run/current-system \
                --ro /dev,/etc,/sys,/proc \
                --rw "$DEV_RW" \
                --ro "$HOME/.gitconfig" \
                --rw "$HOME/.config/claude-code,$HOME/.cache/claude,$HOME/.local/state/claude-code,$HOME/.claude.json,$HOME/.claude,$HOME/.t3" \
                --rwx "$HOME/.claude/skills" \
                --rox "$HOME/.agents/skills" \
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
                ${pkgs.claude-code}/bin/claude "$@"
            '' else ''
              # Run claude directly without sandboxing
              exec ${pkgs.claude-code}/bin/claude "$@"
            ''))
        ];
      };
    };
}
