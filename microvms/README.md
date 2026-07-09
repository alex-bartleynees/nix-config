# MicroVMs

Lightweight NixOS guests managed by [microvm.nix](https://microvm-nix.github.io/microvm.nix/).
Each `.nix` file in this directory is automatically picked up as a `nixosConfigurations` entry.

## VMs

| Name | Purpose | Networking |
|------|---------|------------|
| `dev-vm` | Dev environment with Docker, shell, dev tools | TAP + host NAT, static IP `10.0.0.2` |

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
