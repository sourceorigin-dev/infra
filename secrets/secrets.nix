let
  keys = import ./keys.nix;
  users = [ keys.piquel ];
  systems = with keys; [
    nixosbtw
    piquel-pi
    ovh-1
  ];
in
{
  "tailscale_auth.age".publicKeys = users ++ systems;
  # `cloudflared tunnel create piqueld` credentials JSON.
  "piqueld-cloudflared-tunnel.age".publicKeys = users ++ [ keys.ovh-1 ];
  # Cloudflare API token with Zone:Read and DNS:Edit.
  "piqueld-cloudflare-dns-token.age".publicKeys = users ++ [ keys.ovh-1 ];
  # Signs the Pi's binary cache: `nix key generate-secret --key-name piquel-pi-1`.
  "piquel-pi-cache-key.age".publicKeys = users ++ [ keys.piquel-pi ];
}
