# The Raspberry Pi 5 at home.
{ config, inputs, ... }:
let
  admin = config.admin;
in
{
  hosts.piquel-pi = {
    system = "aarch64-linux";
    address = "100.96.91.58";
    nixosSystem = inputs.nixos-raspberrypi.lib.nixosSystem;
    module =
      { config, pkgs, ... }:
      {
        imports = with inputs.nixos-raspberrypi.nixosModules; [
          ./_hardware-configuration.nix
          raspberry-pi-5.base
          raspberry-pi-5.bluetooth
        ];

        boot.loader.raspberry-pi = {
          bootloader = "kernel";
          # The firmware partition is mounted at /boot (see
          # _hardware-configuration.nix), not nixos-raspberrypi's default
          # /boot/firmware. Writing there put generations in a subdirectory
          # the firmware never reads, so the Pi kept booting a stale one.
          firmwarePath = "/boot";
          # Each generation is a full ~65M copy of kernel, initrd and DTBs on
          # a 487M partition.
          configurationLimit = 2;
        };
        system.nixos.tags =
          let
            cfg = config.boot.loader.raspberry-pi;
          in
          [
            "raspberry-pi-${cfg.variant}"
            cfg.bootloader
            config.boot.kernelPackages.kernel.version
          ];

        networking = {
          networkmanager.enable = true;
          # SSH from the home network over IPv4, for when the tailnet is down.
          # Only from the LAN's own addresses, so nothing forwarded from the
          # internet reaches it.
          firewall.extraCommands = ''
            iptables -I nixos-fw -i end0 -s 192.168.1.0/24 -p tcp --dport 22 -j nixos-fw-accept
          '';
          nameservers = [
            "1.1.1.1"
            "1.0.0.1"
          ];
        };

        users.users.${admin} = {
          extraGroups = [ "networkmanager" ];
          packages = [ pkgs.wakeonlan ];
        };

        system.stateVersion = "25.11";
      };
  };
}
