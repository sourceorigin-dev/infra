# The image registry ovh-1's piqueld pulls built images from, at
# https://piquel-pi.tailfcb6ab.ts.net:5000, with piqueld's build registry
# module. nixosbtw's BuildKit daemon (PiquelChips/dotfiles' build-machine
# module) builds them and pushes them here, so they stay available while
# nixosbtw is off.
#
# It takes no credentials: it listens on loopback, and Tailscale Serve exposes
# it on the tailnet, so the tailnet's access rules decide who may push and
# pull. Deletes are on, for piqueld's image cleanup, and every Sunday at 04:00
# the registry stops for a few minutes to free the deleted images' layers.
{ inputs, ... }:
{
  hosts.piquel-pi.module = {
    imports = [ inputs.piqueld.nixosModules.piqueld-registry ];
    services.piqueld-registry.enable = true;
  };
}
