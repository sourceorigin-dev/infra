{ ... }:
{
  flake.nixosModules.tailscale =
    { config, lib, ... }:
    let
      inherit (lib) mkOption types;
      tailscale = lib.getExe config.services.tailscale.package;
      flags = [
        # By default Tailscale's own firewall rules accept everything from
        # the tailnet ahead of NixOS's. This keeps its rules out of the way,
        # so the tailnet only reaches the ports a host opens on `tailscale0`.
        "--netfilter-mode=nodivert"
        # Settings a node carries over from an earlier install: tailnet names
        # resolve, and SSH stays OpenSSH's.
        "--accept-dns=true"
        "--ssh=false"
      ];
    in
    {
      # Serves local HTTP services on the host's tailnet name over HTTPS, with
      # the tailnet's certificate, which Docker and Nix require of a remote
      # registry or cache. Tailscale Serve answers these ports itself, so the
      # firewall needn't open them, and the tailnet's access rules decide who
      # reaches them.
      options.tailnet.serve = mkOption {
        type = types.attrsOf (
          types.submodule {
            options = {
              port = mkOption {
                type = types.port;
                description = "The HTTPS port on the host's tailnet name.";
              };
              to = mkOption {
                type = types.port;
                description = "The local HTTP port it proxies to, on loopback.";
              };
            };
          }
        );
        default = { };
        example = {
          registry = {
            port = 5000;
            to = 5000;
          };
        };
        description = "Local HTTP services to serve on the tailnet, by name.";
      };

      config = {
        services.tailscale = {
          enable = true;

          # Logs in with this key whenever the node is logged out or stopped at
          # boot. A registered, running node never uses it.
          authKeyFile = config.age.secrets.tailscale_auth.path;

          # Allow Tailscale's UDP port for NAT traversal / direct connections.
          openFirewall = true;
          # Applied on every boot, and when logging in again: `tailscale up`
          # refuses to log in unless it repeats every non-default setting, and
          # `--reset` clears any others carried over from an earlier install.
          extraSetFlags = flags;
          extraUpFlags = flags ++ [ "--reset" ];
        };

        networking.firewall = {
          # Tailscale routes through its own policy routing table, which strict
          # reverse-path filtering can misjudge, dropping tailnet traffic.
          checkReversePath = "loose";
        };

        # Ensure tailscaled starts after the network is up.
        systemd.services = {
          tailscaled = {
            after = [ "network-online.target" ];
            wants = [ "network-online.target" ];
          };
        }
        # Serve keeps its configuration in tailscaled's state, one entry per
        # port. Each unit adds its entry when it starts and removes it when it
        # stops, so one removed from `tailnet.serve` goes away on the next
        # switch.
        // lib.mapAttrs' (
          name: serve:
          lib.nameValuePair "tailnet-serve-${name}" {
            description = "Serve ${name} on the tailnet";
            after = [
              "tailscaled.service"
              "tailscaled-autoconnect.service"
              "tailscaled-set.service"
            ];
            wants = [ "tailscaled.service" ];
            wantedBy = [ "multi-user.target" ];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              ExecStart = "${tailscale} serve --bg --https=${toString serve.port} http://127.0.0.1:${toString serve.to}";
              ExecStop = "${tailscale} serve --https=${toString serve.port} off";
            };
          }
        ) config.tailnet.serve;
      };
    };
}
