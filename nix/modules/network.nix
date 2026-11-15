# Manages the networking
{ ... }:
{
  flake.nixosModules.network =
    { ... }:
    {
      # Publicly, only Tailscale's UDP port is open. SSH is open on the tailnet
      # (the admin module); hosts open what they serve.
      networking.firewall.enable = true;

      # --- Network hardening ------------------------------------------------ #
      # Enable SYN cookies to resist SYN flood attacks.
      boot.kernel.sysctl = {
        "net.ipv4.tcp_syncookies" = 1;
        # Do not accept ICMP redirects (prevents MITM attacks).
        "net.ipv4.conf.all.accept_redirects" = 0;
        "net.ipv6.conf.all.accept_redirects" = 0;
        # Do not send ICMP redirects.
        "net.ipv4.conf.all.send_redirects" = 0;
      };
    };
}
