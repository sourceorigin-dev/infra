# piqueld on ovh-1. Public routes arrive through a Cloudflare Tunnel, so the
# VPS opens no ports; private routes and the dashboard go through its tailnet
# nodes.
{ config, inputs, ... }:
let
  admin = config.admin;
in
{
  hosts.ovh-1.module =
    { config, ... }:
    {
      imports = [ inputs.piqueld.nixosModules.default ];

      # Root-only: systemd hands them to piqueld as credentials.
      age.secrets = {
        piqueld-cloudflared-tunnel.file = ../../../secrets/piqueld-cloudflared-tunnel.age;
        piqueld-cloudflare-dns-token.file = ../../../secrets/piqueld-cloudflare-dns-token.age;
      };

      services.piqueld = {
        enable = true;
        # An older piqueld refuses a database a newer one has migrated. After a
        # system rollback (deploy-rs's, or `nixos-rebuild switch --rollback`)
        # to a generation that also sets this, piqueld restores the newest
        # pre-migration backup it can open before it starts. That undoes every
        # change made since the upgrade; the replaced state stays in
        # /var/lib/piqueld/rolled-back-<time>.
        rollBack = true;
        settings = {
          auth.max_token_days = 365;
          reconciliation.prepare_timeout_seconds = 1200;
          # nixosbtw builds the images (PiquelChips/dotfiles' build-machine
          # module), up to 5 at once, and pushes them to the Pi's registry,
          # which is always on. Builds waiting for a slot count against
          # prepare_timeout_seconds.
          # While nixosbtw is off, a deployment that needs a build fails with
          # builder_unavailable and isn't retried: deploy again once it's on.
          # Building here instead (`unavailable = "local"`) waits on a limit
          # for those builds' resources (PQD-117).
          build = {
            parallel = 5;
            builder = "tcp://nixosbtw.tailfcb6ab.ts.net:1234";
            repository = "piquel-pi.tailfcb6ab.ts.net:5000/piqueld";
          };
          # Previews run alongside production on a VPS with 8 GB. Each preview
          # service gets 512 MB unless it sets its own limit.
          previews.max_total = 8;
          ingress = {
            enabled = true;
            acme.email = "admin@piquel.fr";
            # The dashboard and API are served at dash.piqueld.dev through the
            # private ingress node, which logs its login URL on first start.
            private = {
              enabled = true;
              dashboard_hostname = "dash.piqueld.dev";
            };
            tunnel = {
              enabled = true;
              credentials_file = config.age.secrets.piqueld-cloudflared-tunnel.path;
            };
            webhook_hostname = "hooks.piqueld.dev";
          };
          # Issues private routes' DNS-01 certificates and manages every route's
          # records in the Cloudflare zones.
          dns.providers = [
            {
              kind = "cloudflare";
              api_token_file = config.age.secrets.piqueld-cloudflare-dns-token.path;
              manage_records = true;
            }
          ];
        };
      };

      users.users.${admin}.extraGroups = [ "piqueld" ];

      # Containers reach the tailnet as ovh-1 itself, which includes nixosbtw's
      # build machine and the Pi's registry: neither takes credentials. Only the host may open
      # connections there; replies to tailnet clients still go out. This also
      # keeps applications from calling private routes or the API at
      # dash.piqueld.dev, which are on the tailnet.
      networking.firewall.extraCommands = ''
        iptables -t mangle -N no-tailnet 2>/dev/null || iptables -t mangle -F no-tailnet
        iptables -t mangle -C PREROUTING -j no-tailnet 2>/dev/null || iptables -t mangle -A PREROUTING -j no-tailnet
        iptables -t mangle -A no-tailnet -i docker+ -d 100.64.0.0/10 -m conntrack --ctstate NEW -j DROP
        iptables -t mangle -A no-tailnet -i br-+ -d 100.64.0.0/10 -m conntrack --ctstate NEW -j DROP
      '';
    };
}
