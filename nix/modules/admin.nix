# The operator's account on every host. deploy-rs connects as it.
{ lib, config, ... }:
let
  user = config.admin;
in
{
  options.admin = lib.mkOption {
    type = lib.types.str;
    default = "piquel";
    description = "The operator's user name on every host.";
  };

  config.flake.nixosModules.admin =
    { config, ... }:
    {
      users.users.${user} = {
        isNormalUser = true;
        extraGroups = [ "wheel" ];
        # The software key goes once the second YubiKey is enrolled (PQD-98).
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHVqRluVYJXXoNYyFQzkZm2v2bRnAv/PNuoLRr2G2/Dv piquel@piquel.fr"
          "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIP1SzBK0Kx5/htvjD0egGCCxSDZWzBLI8MKESHlxjuE+AAAACnNzaDpwaXF1ZWw= piquel yubikey 1"
        ];
      };

      # deploy-rs activates through sudo without a terminal, so the operator's SSH
      # key is the root credential.
      security.sudo.wheelNeedsPassword = false;
      # deploy-rs copies closures to the host as this user.
      nix.settings.trusted-users = [ user ];

      services.openssh = {
        enable = true;
        # SSH is never public: it's open on the tailnet only, plus wherever a
        # host opens it itself, such as the Pi's LAN.
        openFirewall = false;
        settings = {
          PasswordAuthentication = false;
          KbdInteractiveAuthentication = false;
          PermitRootLogin = "no";
        };
      };
      networking.firewall.interfaces.tailscale0.allowedTCPPorts = config.services.openssh.ports;
    };
}
