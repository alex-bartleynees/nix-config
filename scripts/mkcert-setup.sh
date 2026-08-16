set -euo pipefail

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
DOCKER_DIR="$SCRIPT_DIR/.."
ENV_FILE="$DOCKER_DIR/.env"
ENV_EXAMPLE="$DOCKER_DIR/.env.example"
CERT_DIR="${CERT_DIR:-$HOME/.local-certs}"
DOMAINS=(gateway nexus-api property-api profile-api localhost 127.0.0.1 ::1)

if ! command -v mkcert >/dev/null 2>&1; then
  echo "mkcert not found on PATH." >&2
  echo "On dev-vm it's installed declaratively via home.packages in nix-config's microvms/dev-vm.nix." >&2
  echo "Rebuild the host (sudo nixos-rebuild switch --flake .#desktop) and run 'microvm -u dev-vm', then retry." >&2
  exit 1
fi

echo "==> Installing local CA (mkcert -install)"
mkcert -install

WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT
pushd "$WORK_DIR" >/dev/null

echo "==> Generating certificate for: ${DOMAINS[*]}"
mkcert "${DOMAINS[@]}"
mkcert -pkcs12 "${DOMAINS[@]}"

LEAF_PEM=$(ls gateway+*.pem | grep -v -- '-key.pem')
LEAF_P12=$(ls gateway+*.p12)

echo "==> Building fullchain.pem"
cat "$LEAF_PEM" "$(mkcert -CAROOT)/rootCA.pem" > fullchain.pem

echo "==> Installing certs to $CERT_DIR"
mkdir -p "$CERT_DIR"
mv "$LEAF_P12" "$CERT_DIR/"
mv fullchain.pem "$CERT_DIR/"

popd >/dev/null

P12_PATH="$CERT_DIR/$(basename "$LEAF_P12")"
FULLCHAIN_PATH="$CERT_DIR/fullchain.pem"
CONTAINER_P12_PATH="/https/$(basename "$LEAF_P12")"

set_env_var() {
  local key="$1" value="$2"
  if grep -q "^${key}=" "$ENV_FILE" 2>/dev/null; then
    sed -i "s|^${key}=.*|${key}=${value}|" "$ENV_FILE"
  else
    printf '%s=%s\n' "$key" "$value" >> "$ENV_FILE"
  fi
}

if [[ ! -f "$ENV_FILE" ]]; then
  echo "==> Creating .env from .env.example"
  cp "$ENV_EXAMPLE" "$ENV_FILE"
fi

echo "==> Updating $ENV_FILE"
set_env_var HTTPS_CERT_VOLUME_PATH "$P12_PATH"
set_env_var CA_CERTIFICATE "fullchain.pem"
set_env_var CA_CERTIFICATE_VOLUME_PATH "$FULLCHAIN_PATH"
set_env_var CA_PATH "$CONTAINER_P12_PATH"
set_env_var CA_PASSWORD "changeit"

echo "==> Done"
echo "  Cert:      $P12_PATH"
echo "  Fullchain: $FULLCHAIN_PATH"
echo "  .env updated: $ENV_FILE"
echo
echo "Run 'docker compose up' from $DOCKER_DIR to start the stack."
