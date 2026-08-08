#!/bin/bash
# exe.dev first-boot setup script.
#
# Installs Nix, clones alex-bartleynees/nix-config, applies the standalone
# Home Manager config (developer + shell tooling - see lib/mk-home-config.nix
# and the "exedev@linux" entry in flake.nix), and switches the exedev
# login shell to zsh.
#
# exe.dev runs this once, as the exedev user (not root), at first boot via
# /exe.dev/setup. Also safe to re-run by hand (git pull + home-manager
# switch are idempotent). exedev has passwordless sudo in this image, used
# below only for the two steps that genuinely need root (/etc/shells, chsh).
#
# Usage:
#   cat scripts/exe-dev-setup.sh | ssh exe.dev new --setup-script /dev/stdin
#
# Or set it as the default for every future VM:
#   cat scripts/exe-dev-setup.sh | ssh exe.dev defaults write dev.exe new.setup-script
set -euxo pipefail

REPO_URL="https://github.com/alex-bartleynees/nix-config.git"
CONFIG_DIR="${HOME}/.config/nix-config"
FLAKE_TARGET="exedev@linux"
NIX_DAEMON_PROFILE="/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"

# 1. Install Nix (idempotent - skip if a prior run already did this). The
# installer self-elevates via sudo for the root-only steps (creating /nix,
# the daemon, build users).
if [ ! -d /nix ]; then
  curl -fsSL https://install.determinate.systems/nix | sh -s -- install --no-confirm
fi

# shellcheck disable=SC1090
source "${NIX_DAEMON_PROFILE}"

# 2. Clone (or fast-forward) the nix config.
mkdir -p "$(dirname "${CONFIG_DIR}")"
if [ -d "${CONFIG_DIR}/.git" ]; then
  git -C "${CONFIG_DIR}" pull --ff-only
else
  git clone "${REPO_URL}" "${CONFIG_DIR}"
fi

# 3. Apply the standalone Home Manager config. -b backs up any file that
# already exists unmanaged (e.g. this image's baked-in ~/.gitconfig)
# instead of failing activation outright.
nix run home-manager/master -- switch -b backup --flake "${CONFIG_DIR}#${FLAKE_TARGET}"

# 4. Make zsh the login shell (needs root).
ZSH_PATH="${HOME}/.nix-profile/bin/zsh"
grep -qxF "${ZSH_PATH}" /etc/shells || echo "${ZSH_PATH}" | sudo tee -a /etc/shells >/dev/null
sudo chsh -s "${ZSH_PATH}" "$(id -un)"

echo "nix-config bootstrap complete for $(id -un)."
