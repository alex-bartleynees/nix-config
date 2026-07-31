# Syncthing: adding hosts and folders

Runbook for `modules/syncthing.nix` — generating a host's device identity,
storing it in sops, and wiring it into a profile so two (or more) hosts sync
a folder declaratively (no GUI pairing needed).

Worked example already in the repo: `desktop` and `wsl` sync
`~/Documents/obsidian-vault`, wired in `profiles/gaming-workstation.nix` and
`profiles/wsl.nix` respectively.

## How device IDs work

A device ID is not a password — it's a SHA-256 hash of the host's TLS cert,
Base32-encoded. It's derived entirely from `cert.pem`, so it's safe to write
in plaintext directly into host config; only the paired `key.pem` is secret
and that's what goes into sops. Regenerating a host's key/cert changes its
device ID, so every peer that trusts it needs updating too.

## 1. Prerequisites

- The host must already be an sops recipient in `.sops.yaml`. All of this
  user's personal machines (`desktop`, `wsl`, `thinkpad`, `media`, `macbook`)
  share the same `alexbn` age key already, so nothing to do there.
  For a brand-new machine with its own age key (e.g. a fresh microvm), see
  `microvms/README.md`'s "First-boot: sops age key bootstrap" section, then
  run `sops updatekeys secrets/secrets.yaml` after adding it to `.sops.yaml`.
- `sops`, `jq`, and `nix` on the machine you're running these commands from
  (doesn't have to be the target host — device identities can be generated
  and encrypted from any machine with sops decrypt access).

## 2. Generate the host's identity

Pick a short name for the host (matches what you'll use in
`settings.devices.<name>` below — convention is the NixOS host name).

```bash
HOST=desktop   # change per host
DIR=$(mktemp -d)
nix run nixpkgs#syncthing -- generate --home "$DIR"
```

This prints the device ID — copy it, you'll need it on the *other* host's
side:

```
INF Calculated device ID (device=H5XLOT2-MRE2ZF7-5SM7FHW-Y56VK6Y-3H7B5LF-3DDYVZC-MP5R2GK-ZI4ZEQB log.pkg=github)
```

`$DIR` now has `key.pem` and `cert.pem`. `config.xml` is discarded — the
module only needs the key/cert pair.

## 3. Encrypt the key/cert into secrets.yaml

**Don't** do `sops -d secrets/secrets.yaml > file` — that dumps every secret
in the file to plaintext, not just this host's. Use `sops set` instead,
which patches one key in place without ever writing the full file's
plaintext to disk:

```bash
key_json=$(jq -Rs . < "$DIR/key.pem")
cert_json=$(jq -Rs . < "$DIR/cert.pem")

sops set secrets/secrets.yaml "[\"syncthing\"][\"$HOST\"][\"key\"]"  "$key_json"
sops set secrets/secrets.yaml "[\"syncthing\"][\"$HOST\"][\"cert\"]" "$cert_json"
```

Sanity-check the structure (key *names* only, never decrypt values to
stdout):

```bash
nix run nixpkgs#yq-go -- '.syncthing | keys' secrets/secrets.yaml
```

Then shred the plaintext key material — it's encrypted in sops now, no
reason for a second copy to exist on disk:

```bash
shred -u "$DIR/key.pem" "$DIR/cert.pem"
rm -rf "$DIR"
```

## 4. Wire it into the host's profile

Not `hosts.nix` — that file is host metadata only. Put the config in
whichever `profiles/*.nix` file is gated for this host (e.g.
`profiles/gaming-workstation.nix` for `desktop`, `profiles/wsl.nix` for
`wsl`), inside the existing `lib.mkIf config.profiles.<name> { ... }` block:

```nix
sops.secrets = {
  "syncthing/${HOST}/key" = {
    owner = "alexbn";
    group = "users";
    mode = "0400";
  };
  "syncthing/${HOST}/cert" = {
    owner = "alexbn";
    group = "users";
    mode = "0400";
  };
};

syncthing = {
  enable = true;
  user = "alexbn";   # run as the folder-owning user, not the module's
  group = "users";   # default dedicated "syncthing" system user
  identity.keyFile = config.sops.secrets."syncthing/${HOST}/key".path;
  identity.certFile = config.sops.secrets."syncthing/${HOST}/cert".path;
  settings = {
    devices.<peer-name>.id = "<PEER'S DEVICE ID>";
    folders."<folder-name>" = {
      path = "/home/alexbn/<path>";
      devices = [ "<peer-name>" ];
    };
  };
};
```

Do the mirror image on the peer's own profile: its `devices.<this-host>.id`
is the ID printed in step 2, and its folder path/devices list points back.

Repeat steps 2–4 for each additional host, adding it to every existing
peer's `devices`/folder `devices` list.

## 5. Persistence (impermanence hosts only)

If the host resets its root filesystem on boot (check for
`impermanence.enable = true` reachable from its profile chain), Syncthing's
own state — device identity cache, index database — needs to survive that.
It's already added once, host-wide, in `lib/root-persistence.nix`:

```nix
"/var/lib/syncthing" # Syncthing state (device identity, index database)
```

Nothing to do per-host as long as `dataDir`/`configDir` stay at the module
default (`/var/lib/syncthing`). Hosts without impermanence (e.g. `wsl`) don't
need this at all.

## 6. Verify before deploying

```bash
nix eval --json '.#nixosConfigurations.<host>.config.syncthing' \
  --apply 'c: { enable = c.enable; devices = builtins.attrNames c.settings.devices; folders = builtins.attrNames c.settings.folders; }'

nix build '.#nixosConfigurations.<host>.config.system.build.toplevel' --dry-run
```

Repeat for the peer host. Both should show `enable = true` and list each
other in `devices`.

## 7. Deploy

```bash
sudo nixos-rebuild switch --flake .#<host>
```

Deploy both sides. First sync may go through global discovery/relay rather
than LAN if the two hosts aren't locally reachable — slower, but automatic,
nothing to configure.

## Adding a folder to hosts that already sync

If two hosts already trust each other (steps 1–3 done), adding another
shared folder is just step 4's `settings.folders` block on both sides —
no new keys needed.

## Adding a third host to an existing folder

Run steps 2–4 for the new host, then update *every* existing peer's
`settings.devices` (add the new host's ID) and that folder's `devices` list
(add the new host's name) — not just the new host's own config.
