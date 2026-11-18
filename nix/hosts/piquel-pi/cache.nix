# A Nix binary cache at https://piquel-pi.tailfcb6ab.ts.net, on the tailnet
# only. nixosbtw (PiquelChips/dotfiles' pi-cache-push module) pushes every path
# it builds here, and every host substitutes from it (nix/modules/base.nix).
let
  keys = import ../../../secrets/keys.nix;
  port = 5001;
in
{
  hosts.piquel-pi.module =
    { config, lib, ... }:
    {
      age.secrets.piquel-pi-cache-key.file = ../../../secrets/piquel-pi-cache-key.age;

      # Serves the store as it is, signing each path as it serves it.
      services.harmonia.cache = {
        enable = true;
        signKeyPaths = [ config.age.secrets.piquel-pi-cache-key.path ];
        # The registry has port 5000.
        settings.bind = "127.0.0.1:${toString port}";
      };
      tailnet.serve.cache = {
        port = 443;
        to = port;
      };

      # nixosbtw logs in with its host key as `nix-ssh`, which may only speak
      # the Nix daemon's protocol. It's trusted, so it may add paths without
      # signatures, which harmonia then signs: nixosbtw can put anything in
      # the cache every host trusts, and a trusted user is as good as root on
      # the Pi. nixosbtw already builds and deploys every host, so that grants
      # it nothing new.
      nix.sshServe = {
        enable = true;
        protocol = "ssh-ng";
        trusted = true;
        keys = [ keys.nixosbtw ];
      };

      # Pushed paths have no garbage collector roots, so a scheduled
      # collection would empty the cache. Nix collects only once less than
      # 100 GiB is free, until 200 GiB is. That never deletes the Pi's own
      # old system generations, which the scheduled one did: a few GB each,
      # against 2 TB.
      nix.gc.automatic = lib.mkForce false;
      nix.settings = {
        min-free = 100 * 1024 * 1024 * 1024;
        max-free = 200 * 1024 * 1024 * 1024;
      };
    };
}
