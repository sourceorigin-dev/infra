# Public SSH keys: the operator's, and each machine's host key. agenix encrypts
# secrets to them (secrets.nix), and hosts trust a machine's key where it logs
# in as itself, such as nixosbtw pushing to the Pi's binary cache.
{
  piquel = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHVqRluVYJXXoNYyFQzkZm2v2bRnAv/PNuoLRr2G2/Dv";

  nixosbtw = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL2JWt8eVq7rh8Iv41c78xhW3MGKn5m7MBNQ/3iLUWM8";
  piquel-pi = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKtrAhMMQ4WDysvu1zbxrnARtl+B0TwR1ov5MC8Wut0F";
  ovh-1 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID76ACe5RwD38FnSZFeS7AC36rvLD42LN6fLQ9yUnbTX";
}
