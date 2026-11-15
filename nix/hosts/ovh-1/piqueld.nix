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
        settings = {
          auth.max_token_days = 365;
          # The daemon's own tailnet node. It and the private ingress node log
          # their login URLs on first start.
          tailscale = {
            enabled = true;
            hostname = "piqueld";
          };
          reconciliation.prepare_timeout_seconds = 1200;
          # nixosbtw builds the images and keeps them in its registry
          # (PiquelChips/dotfiles' build-machine module). While it's off,
          # deployments that need a build fail and are deployed again later.
          build = {
            builder = "tcp://nixosbtw.tailfcb6ab.ts.net:1234";
            repository = "nixosbtw.tailfcb6ab.ts.net:5000/piqueld";
          };
          # At 512 MB each by default, 8 previews leave half the VPS's memory to
          # everything else.
          previews.max_total = 8;
          ingress = {
            enabled = true;
            acme.email = "admin@piquel.fr";
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
    };
}
