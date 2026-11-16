# A Nix binary cache at https://piquel-pi.tailfcb6ab.ts.net, on the tailnet
# only. nixosbtw (PiquelChips/dotfiles' binary-cache module) pushes every path
# it builds here, and every host substitutes from it (nix/modules/cache.nix).
let
  keys = import ../../../secrets/keys.nix;
in
{
  hosts.piquel-pi.module =
    { config, ... }:
    {
      age.secrets.piquel-pi-cache-key.file = ../../../secrets/piquel-pi-cache-key.age;

      # Serves the store as it is, signing each path as it serves it.
      services.harmonia.cache = {
        enable = true;
        signKeyPaths = [ config.age.secrets.piquel-pi-cache-key.path ];
        # The registry has port 5000.
        settings.bind = "127.0.0.1:5001";
      };
      tailnet.serve.cache = {
        port = 443;
        to = 5001;
      };

      # nixosbtw logs in with its host key as `nix-ssh`, which may only speak
      # the Nix daemon's protocol. It's trusted, so it may add paths without
      # signatures, which harmonia then signs: nixosbtw can put anything in
      # the cache every host trusts.
      nix.sshServe = {
        enable = true;
        protocol = "ssh-ng";
        write = true;
        trusted = true;
        keys = [ keys.nixosbtw ];
      };

      # Pushed paths have no garbage collector roots, so a scheduled
      # collection would empty the cache. Nix collects only once less than
      # 100 GiB is free, until 200 GiB is.
      nix.gc.automatic = false;
      nix.settings = {
        min-free = 100 * 1024 * 1024 * 1024;
        max-free = 200 * 1024 * 1024 * 1024;
      };
    };
}
