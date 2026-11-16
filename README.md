# infra

NixOS configuration for the operator's machines, deployed with
[deploy-rs](https://github.com/serokell/deploy-rs).

## Layout

Every file under `nix/` is a [flake-parts](https://flake.parts) module, imported
with [import-tree](https://github.com/vic/import-tree). Paths containing `/_` are
skipped: they hold plain NixOS modules, such as hardware configurations.

- `nix/hosts.nix`: the host registry. Each `hosts.<name>` entry becomes
  `nixosConfigurations.<name>` and the deploy-rs node `deploy.nodes.<name>`.
- `nix/hosts/<name>/`: a host's entry and its own configuration.
- `nix/modules/`: NixOS modules every host imports, as `nixosModules.<name>`.
- `secrets/`: [agenix](https://github.com/ryantm/agenix) secrets and their recipients.

## Deploying

From `nix develop`, which provides `deploy`, `nixos-anywhere` and `agenix`:

```sh
deploy .#piquel-pi
```

deploy-rs connects as the operator's user, `piquel` (the `admin` option in
`nix/modules/admin.nix`), and activates through passwordless sudo. If the host
stops answering after activation, it rolls back to the previous generation.

`nix flake check` evaluates every host and builds the deploy checks for the
current platform's hosts.

## SSH

SSH is never public. Every host opens it on the tailnet only (`tailscale0`), and
the Pi also on its LAN, for when the tailnet is down.

## Storage on the Pi

The Pi, which is always on, keeps what other machines build, on the tailnet
only:

- **Images:** ovh-1's piqueld pulls built images from the registry at
  `piquel-pi.tailfcb6ab.ts.net:5000`. nixosbtw builds them and pushes them there.
- **Nix:** a binary cache at `https://piquel-pi.tailfcb6ab.ts.net`, with the key
  `piquel-pi-1:bKIz75gwV7RfJ6uT1YI+fUYbGk1uptOl9Vlu/jR+r0w=`. nixosbtw pushes
  every path it builds, and every host here substitutes from it. Another
  machine can use it by adding both to its `extra-substituters` and
  `extra-trusted-public-keys`.

The Pi builds neither: it would have to emulate x86_64.

## Installing a host

A new host is installed over SSH with
[nixos-anywhere](https://github.com/nix-community/nixos-anywhere), which wipes
its disk. Its SSH host key is made beforehand, so its secrets decrypt on first
boot:

1. Generate the host key in a private folder, outside the repo:

   ```sh
   install -d -m 700 ~/<name>-install
   install -d -m 755 ~/<name>-install/etc ~/<name>-install/etc/ssh
   ssh-keygen -t ed25519 -N "" -C root@<name> -f ~/<name>-install/etc/ssh/ssh_host_ed25519_key
   ```

2. Add the public key to `secrets/secrets.nix`, then re-encrypt with
   `cd secrets && agenix -r`.
3. Allow root to log in over SSH with the operator's key on the target.
4. To keep a machine's tailnet identity and address, copy its
   `tailscaled.state` to `~/<name>-install/var/lib/tailscale/`, mode 600,
   with the folders above it mode 755: the install copies folders' modes, and
   sshd can't read keys under a `/etc/ssh` only root can open.
   Copy it without running `tailscale down` first, or the machine boots logged
   out. Otherwise it logs in with `tailscale_auth`, which must still be valid.
5. Install, then delete the folder:

   ```sh
   nixos-anywhere --flake .#<name> --extra-files ~/<name>-install root@<public address>
   ```

   The installer has no Tailscale, so this uses the machine's public address.

6. Check that SSH answers over the tailnet, and from outside that it no longer
   answers on the host's public addresses.

## Rescue

- **piquel-pi:** SSH over the LAN; from away, through nixosbtw's screen on the KVM.
- **ovh-1:** open its KVM console in the OVH control panel and pick an
  older generation in the GRUB menu at boot. If it can't boot at all, boot OVH's
  rescue mode, mount its disk on `/mnt`, make its store visible with
  `mkdir /nix && mount --bind /mnt/nix /nix`, and enter it with
  `/nix/var/nix/profiles/system/sw/bin/nixos-enter --root /mnt`. No account
  has a password, so the console can't log in.

piqueld's database migrations only go forward, so rolling back past a piqueld
upgrade also needs its data restored. Back it up before upgrading piqueld, as
in its [backups and upgrades guide](https://github.com/sourceorigin-dev/piqueld/blob/main/docs/user/operations/backups.md).
