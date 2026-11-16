# The image registry ovh-1's piqueld pulls built images from, at
# https://piquel-pi.tailfcb6ab.ts.net:5000. nixosbtw's BuildKit daemon
# (PiquelChips/dotfiles' build-machine module) builds them and pushes them here,
# so they stay available while nixosbtw is off.
{
  hosts.piquel-pi.module = {
    # It listens on loopback only and has no credentials: the tailnet reaches
    # it through Tailscale Serve, so the tailnet's access rules decide who may
    # push and pull.
    services.dockerRegistry = {
      enable = true;
      port = 5000;
      # piqueld will delete the images no deployment uses any more
      # (PQD-113). Garbage collection, which frees their
      # layers, stays off until then: it restarts the registry, which would
      # fail a push in progress.
      enableDelete = true;
    };
    tailnet.serve.registry = {
      port = 5000;
      to = 5000;
    };
  };
}
