# MicroVMs

Lightweight NixOS guests managed by [microvm.nix](https://microvm-nix.github.io/microvm.nix/).
Each `.nix` file in this directory is automatically picked up as a `nixosConfigurations` entry.

## VMs

| Name | Purpose | Networking |
|------|---------|------------|
| `dev-vm` | Dev environment with Docker, shell, dev tools | TAP + host NAT, static IP `10.0.0.2` |
| `agent-vm` | Runs `netclawd` (self-hosted AI agent daemon) as a dedicated `netclaw` user, hosted on `media` | TAP + host NAT, static IP `10.0.1.2` |

---

## dev-vm

### Enabling on the desktop host

Add to your desktop host config (e.g. in `hosts.nix` additionalModules or a host-specific module):

```nix
microvmHost.enable = true;
```

Then rebuild:

```bash
sudo nixos-rebuild switch --flake .#desktop
```

### Starting and stopping

The VM starts automatically on host boot via `autostart = true` in `modules/microvm.nix`. Manage it like any systemd service:

```bash
systemctl status microvm@dev-vm      # check status
systemctl start  microvm@dev-vm      # start manually
systemctl stop   microvm@dev-vm      # stop
journalctl -u microvm@dev-vm -f      # follow logs
```

### SSH host keys (one-time setup)

The VM uses pre-generated SSH host keys shared from the host so the key stays stable
across VM reboots. Without this you get a "host identification has changed" warning
every time the VM restarts.

Generate the keys once (never needs to be repeated):

```bash
mkdir -p ~/.config/microvm/dev-vm/ssh-host-keys
ssh-keygen -t ed25519 -N "" \
  -f ~/.config/microvm/dev-vm/ssh-host-keys/ssh_host_ed25519_key
```

Then rebuild and restart the VM (see [Updating the VM](#updating-the-vm)).

If you previously connected to `10.0.0.2` with the old ephemeral key, clear the stale
entry before reconnecting:

```bash
ssh-keygen -R 10.0.0.2
```

### Connecting via SSH

The VM has a static IP on the TAP subnet — SSH directly, no port forwarding needed:

```bash
ssh alexbn@10.0.0.2
```

Add this to `~/.ssh/config` for convenience:

```
Host dev-vm
    HostName 10.0.0.2
    User alexbn
```

Then just: `ssh dev-vm`

### Networking

The VM uses TAP + host NAT:

- `10.0.0.1` — host end of the TAP link (`vm-dev` interface on host)
- `10.0.0.2` — VM static IP
- The host NATtingmasquerades VM traffic through `wlp7s0` (WiFi)

All ports on `10.0.0.2` are directly reachable from the host — no port forwarding
config needed. If you run a dev server on port 3000 inside the VM, `curl 10.0.0.2:3000`
works immediately from the host.

If the active internet interface changes (e.g. you plug in Ethernet), update
`microvmHost.externalInterface` in your desktop host config and rebuild.

### Workspaces share

`/home/alexbn/workspaces` on the host is mounted at the same path inside the VM via virtiofs.
Edits on either side are immediately visible on the other — no sync needed.

The `/nix/store` is also shared read-only from the host, so packages don't need to be
rebuilt inside the VM.

### Docker

Docker is enabled inside the VM. Use it normally after SSHing in:

```bash
docker run --rm hello-world
docker compose up
```

Containers can reach the internet via QEMU's NAT. To access a container port from your host,
forward the container's port to a guest port, then forward that guest port to the host
via `microvm.forwardPorts`.

---

## agent-vm

Runs `netclawd` (from the [netclaw-nix](https://github.com/alex-bartleynees/netclaw-nix) flake input) as a
dedicated, unprivileged `netclaw` user — isolated from the host and from `dev-vm`.

### One-time host-side prerequisites

`agent-vm` doesn't share `workspaces`/`Documents` from the host (that's `dev-vm`-only —
see `extraShares` in `microvms/dev-vm.nix`). It does share a single dedicated folder for
easy file drop-off, and needs SSH host keys generated under
`~/.config/microvm/<hostName>/ssh-host-keys` — both required to exist on the **host**
before first boot:

```bash
mkdir -p /home/alexbn/agent-vm-share
mkdir -p ~/.config/microvm/agent-vm/ssh-host-keys
ssh-keygen -t ed25519 -N "" \
  -f ~/.config/microvm/agent-vm/ssh-host-keys/ssh_host_ed25519_key
```

`/home/alexbn/agent-vm-share` on the host is mounted at `/home/netclaw/share` inside the
VM via virtiofs — edits on either side are immediately visible on the other, same
mechanism as `dev-vm`'s `workspaces` share, just a single folder instead of the whole
dev environment.

### Enabling

Already wired into `desktop`'s `microvmHost.vms` automatically (derived from
`microvms/lib/microvm-vms.nix`). Just rebuild:

```bash
sudo nixos-rebuild switch --flake .#desktop
```

### sops age key bootstrap (required for the OpenAI API key secret)

Unlike `dev-vm`, the `netclaw` account deliberately has **no `wheel`/sudo access** — it's
the account `netclawd` itself runs as, and this is an AI agent daemon with its own tool/skill
execution, so it should never have a path to root. Key generation instead runs as a
declarative root oneshot (`systemd.services.netclaw-age-key-bootstrap` in `agent-vm.nix`)
that fires automatically on first boot and leaves only the **public** key world-readable.

```bash
sudo nixos-rebuild switch --flake .#desktop
microvm -u agent-vm
ssh netclaw@10.0.1.2 cat /var/lib/sops-nix/age-key.pub   # no sudo needed
```

Then from the host: replace the `&agent-vm` placeholder in `.sops.yaml` with that printed
key, add `*agent-vm` to `key_groups.age`, run `sops updatekeys secrets/secrets.yaml`, add
the real key under `netclaw.openai-api-key` via `sops secrets/secrets.yaml`, commit, rebuild
`desktop`, then `microvm -u agent-vm` once more so `netclawd` can decrypt it.

### Verifying

```bash
ssh netclaw@10.0.1.2
netclaw doctor
journalctl -u netclawd -f
netclaw chat -p "say hi"   # confirms the OpenAI provider is reachable end-to-end
```

Model selection (`NETCLAW_Models__Main__*`) isn't pre-set via secrets — run
`netclaw init` or `netclaw model` inside the VM once the provider key is live.

---

## Updating the VM

After changing `microvms/dev-vm.nix`, rebuild and update:

```bash
# Rebuild the host (picks up the new VM definition)
sudo nixos-rebuild switch --flake .#desktop

# Push the update into the running VM
microvm -u dev-vm
```

---

## First-boot: sops age key bootstrap

The VM uses `secrets/secrets.yaml` for secrets (e.g. the user password) but needs its
own age key to decrypt them. On first boot the `initialHashedPassword` from
`users/alexbn.nix` is used as a fallback.

**To set up full sops decryption:**

1. SSH in (using the `initialHashedPassword` from `users/alexbn.nix`)
2. Generate the VM's age key:
   ```bash
   sudo mkdir -p /var/lib/sops-nix
   sudo age-keygen -o /var/lib/sops-nix/age-key.txt
   # Note the public key printed to stdout
   ```
3. Add the public key to `.sops.yaml` in the repo under a `dev-vm` recipient
4. Re-encrypt the secrets file from your host:
   ```bash
   sops updatekeys secrets/secrets.yaml
   ```
5. Commit and rebuild — `hashedPasswordFile` will now decrypt correctly

The age key is persisted in the `/var` volume (`var.img`) so it survives VM reboots.

---

## Future: bridge networking (wired Ethernet)

The current setup uses TAP + host NAT. If you plug in Ethernet (`enp6s0`) and want
the VM to have its own LAN IP visible to other devices on the network:

1. Uncomment the bridge networking block in `modules/microvm.nix`
2. Set `lanInterface`, `bridgeAddress`, and `gateway` for your network
3. Update `dev-vm.nix` guest static IP to a free address on your LAN
4. Handle the NetworkManager conflict (either disable NM or mark `br0`/`vm-*` as unmanaged)
5. Rebuild host and restart VM

See [microvm.nix networking docs](https://microvm-nix.github.io/microvm.nix/) for full details.
