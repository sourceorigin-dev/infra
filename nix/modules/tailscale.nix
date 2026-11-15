{ ... }:
{
  flake.nixosModules.tailscale =
    { config, ... }:
    {
      services.tailscale = {
        enable = true;

        # Logs in with this key whenever the node is logged out or stopped at
        # boot. A registered, running node never uses it.
        authKeyFile = config.age.secrets.tailscale_auth.path;

        # Allow Tailscale's UDP port for NAT traversal / direct connections.
        openFirewall = true;
        extraSetFlags = [
          # By default Tailscale's own firewall rules accept everything from
          # the tailnet ahead of NixOS's. This keeps its rules out of the way,
          # so the tailnet only reaches the ports a host opens on `tailscale0`.
          "--netfilter-mode=nodivert"
          # Settings a node carries over from an earlier install: tailnet names
          # resolve, and SSH stays OpenSSH's.
          "--accept-dns=true"
          "--ssh=false"
        ];
      };

      networking.firewall = {
        # Tailscale routes through its own policy routing table, which strict
        # reverse-path filtering can misjudge, dropping tailnet traffic.
        checkReversePath = "loose";
      };

      # Ensure tailscaled starts after the network is up.
      systemd.services.tailscaled = {
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
      };
    };
}
