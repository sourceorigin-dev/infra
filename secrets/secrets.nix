let
  # Piquel's personal public key
  piquel = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHVqRluVYJXXoNYyFQzkZm2v2bRnAv/PNuoLRr2G2/Dv";
  users = [ piquel ];

  nixosbtw = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL2JWt8eVq7rh8Iv41c78xhW3MGKn5m7MBNQ/3iLUWM8";
  piquel-pi = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKtrAhMMQ4WDysvu1zbxrnARtl+B0TwR1ov5MC8Wut0F";
  piquel-fr = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID76ACe5RwD38FnSZFeS7AC36rvLD42LN6fLQ9yUnbTX";

  systems = [
    nixosbtw
    piquel-pi
    piquel-fr
  ];
in
{
  "tailscale_auth.age".publicKeys = users ++ systems;
  # Cloudflare API token with Zone:Read and DNS:Edit.
  "piqueld-cloudflare-dns-token.age".publicKeys = users ++ [ piquel-fr ];
}
