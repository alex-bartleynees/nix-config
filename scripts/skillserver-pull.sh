#!/usr/bin/env bash
#
# skillserver-pull.sh
#
# Pulls the latest version of every skill from a self-hosted SkillServer
# instance into one canonical directory, then symlinks the per-agent
# locations to it so Claude Code, OpenCode, and Codex CLI all see the
# same skills without duplicating files:
#
#   ~/.agents/skills/   <- canonical store, synced from SkillServer
#                           (OpenCode reads this natively)
#   ~/.claude/skills     -> symlink to ~/.agents/skills   (Claude Code)
#   ~/.codex/skills       -> symlink to ~/.agents/skills   (Codex CLI)
#
# Only re-downloads a skill when its version has changed, so it's cheap
# to run frequently (cron / systemd timer / login hook).
#
# Requires: curl, jq, unzip
#
# Usage:
#   skillserver-pull [options]
#
# Options:
#   -u, --url URL        SkillServer base URL (default: $SKILLSERVER_URL or https://skills.alexbartleynees.com)
#   -d, --dest DIR        Canonical skills directory (default: ~/.agents/skills)
#   -l, --links LIST      Comma-separated list of paths to symlink to the
#                          canonical directory (default: ~/.claude/skills,~/.codex/skills)
#       --no-links        Skip creating/checking symlinks entirely
#   -p, --prune           Remove local skills that no longer exist on the server
#       --dry-run         Show what would happen without changing anything
#   -q, --quiet           Suppress per-skill "up to date" noise
#   -h, --help            Show this help
#
# Notes on symlinking:
#   If a link path already exists as a real directory (not a symlink),
#   it is moved aside to <path>.bak-<timestamp> before the symlink is
#   created, so nothing you've hand-placed there is silently lost.
#
# Env vars:
#   SKILLSERVER_URL       Same as --url

set -euo pipefail

# ---------- defaults ----------
BASE_URL="${SKILLSERVER_URL:-https://skills.alexbartleynees.com}"
CANONICAL_DIR="${HOME}/.agents/skills"
LINKS="${HOME}/.claude/skills,${HOME}/.codex/skills"
DO_LINKS=1
PRUNE=0
DRY_RUN=0
QUIET=0

# ---------- arg parsing ----------
while [[ $# -gt 0 ]]; do
  case "$1" in
    -u|--url) BASE_URL="$2"; shift 2 ;;
    -d|--dest) CANONICAL_DIR="$2"; shift 2 ;;
    -l|--links) LINKS="$2"; shift 2 ;;
    --no-links) DO_LINKS=0; shift ;;
    -p|--prune) PRUNE=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    -q|--quiet) QUIET=1; shift ;;
    -h|--help)
      grep '^#' "$0" | sed -e '1d' -e 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

BASE_URL="${BASE_URL%/}"

# ---------- dependency check ----------
for cmd in curl jq unzip; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Error: required command '$cmd' not found in PATH." >&2
    exit 1
  fi
done

log()  { [[ "$QUIET" -eq 1 ]] || echo "$@"; }
warn() { echo "$@" >&2; }
act()  { if [[ "$DRY_RUN" -eq 1 ]]; then echo "[dry-run] $*"; else eval "$@"; fi; }

mkdir -p "$CANONICAL_DIR"

# ---------- fetch skill index ----------
log "Syncing skills from ${BASE_URL} -> ${CANONICAL_DIR}"

skills_json="$(curl -fsSL "${BASE_URL}/api/v1/skills" || true)"
if [[ -z "$skills_json" ]]; then
  warn "Error: could not reach ${BASE_URL}/api/v1/skills"
  exit 1
fi

skill_names="$(echo "$skills_json" | jq -r '.[].name // .items[]?.name // empty' 2>/dev/null)"
if [[ -z "$skill_names" ]]; then
  skill_names="$(echo "$skills_json" | jq -r '.[]' 2>/dev/null || true)"
fi

if [[ -z "$skill_names" ]]; then
  warn "No skills returned by server, or unexpected response shape."
  exit 0
fi

tmp_root="$(mktemp -d)"
trap 'rm -rf "$tmp_root"' EXIT

synced=0
skipped=0
failed=0
seen_names=()

while IFS= read -r name; do
  [[ -z "$name" ]] && continue
  seen_names+=("$name")

  latest_json="$(curl -fsSL "${BASE_URL}/api/v1/skills/${name}/latest" || true)"
  if [[ -z "$latest_json" ]]; then
    warn "  [$name] failed to fetch latest metadata, skipping"
    failed=$((failed + 1))
    continue
  fi

  version="$(echo "$latest_json" | jq -r '.version // empty')"
  has_archive="$(echo "$latest_json" | jq -r 'if .isArchive == true or .hasArchive == true then "1" else "0" end')"

  if [[ -z "$version" ]]; then
    warn "  [$name] no version field in response, skipping"
    failed=$((failed + 1))
    continue
  fi

  skill_dir="${CANONICAL_DIR}/${name}"
  version_stamp="${skill_dir}/.skillserver-version"

  if [[ -f "$version_stamp" ]] && [[ "$(cat "$version_stamp")" == "$version" ]]; then
    log "  [$name] up to date (${version})"
    skipped=$((skipped + 1))
    continue
  fi

  log "  [$name] ${version} -> syncing"

  if [[ "$DRY_RUN" -eq 1 ]]; then
    synced=$((synced + 1))
    continue
  fi

  work_dir="${tmp_root}/${name}"
  mkdir -p "$work_dir"

  if [[ "$has_archive" == "1" ]]; then
    if curl -fsSL "${BASE_URL}/api/v1/skills/${name}/${version}/archive.zip" -o "${work_dir}/archive.zip"; then
      rm -rf "$skill_dir"
      mkdir -p "$skill_dir"
      unzip -q -o "${work_dir}/archive.zip" -d "$skill_dir"
    else
      warn "  [$name] archive download failed"
      failed=$((failed + 1))
      continue
    fi
  else
    if curl -fsSL "${BASE_URL}/api/v1/skills/${name}/${version}/SKILL.md" -o "${work_dir}/SKILL.md"; then
      rm -rf "$skill_dir"
      mkdir -p "$skill_dir"
      mv "${work_dir}/SKILL.md" "${skill_dir}/SKILL.md"
    else
      warn "  [$name] SKILL.md download failed"
      failed=$((failed + 1))
      continue
    fi
  fi

  echo "$version" > "$version_stamp"
  synced=$((synced + 1))
done <<< "$skill_names"

# ---------- prune local skills not on the server ----------
if [[ "$PRUNE" -eq 1 ]] && [[ -d "$CANONICAL_DIR" ]]; then
  for local_dir in "$CANONICAL_DIR"/*/; do
    [[ -d "$local_dir" ]] || continue
    local_name="$(basename "$local_dir")"
    [[ -f "${local_dir}.skillserver-version" ]] || continue  # only prune server-managed skills
    match=0
    for n in "${seen_names[@]:-}"; do
      [[ "$n" == "$local_name" ]] && match=1 && break
    done
    if [[ "$match" -eq 0 ]]; then
      log "  [$local_name] no longer on server, pruning"
      act "rm -rf \"$local_dir\""
    fi
  done
fi

# ---------- symlink per-agent locations to the canonical store ----------
if [[ "$DO_LINKS" -eq 1 ]]; then
  log ""
  log "Checking agent symlinks..."
  IFS=',' read -ra link_paths <<< "$LINKS"
  for link_path in "${link_paths[@]}"; do
    link_path="${link_path/#\~/$HOME}"   # expand leading ~
    parent_dir="$(dirname "$link_path")"

    if [[ -L "$link_path" ]]; then
      current_target="$(readlink "$link_path")"
      if [[ "$current_target" == "$CANONICAL_DIR" ]]; then
        log "  [$link_path] already linked"
        continue
      else
        log "  [$link_path] relinking (was -> $current_target)"
        act "rm \"$link_path\""
        act "ln -s \"$CANONICAL_DIR\" \"$link_path\""
      fi
    elif [[ -d "$link_path" ]]; then
      backup="${link_path}.bak-$(date +%Y%m%d%H%M%S)"
      warn "  [$link_path] exists as a real directory, backing up -> $backup"
      act "mkdir -p \"$parent_dir\""
      act "mv \"$link_path\" \"$backup\""
      act "ln -s \"$CANONICAL_DIR\" \"$link_path\""
    elif [[ -e "$link_path" ]]; then
      warn "  [$link_path] exists and is not a directory, skipping"
    else
      log "  [$link_path] creating symlink -> $CANONICAL_DIR"
      act "mkdir -p \"$parent_dir\""
      act "ln -s \"$CANONICAL_DIR\" \"$link_path\""
    fi
  done
fi

log ""
log "Done. synced=${synced} up-to-date=${skipped} failed=${failed}"
[[ "$failed" -gt 0 ]] && exit 2
exit 0
