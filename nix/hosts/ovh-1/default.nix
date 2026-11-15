# The OVH VPS (4 vCPUs, 8 GB, 160 GB) that runs piqueld. Installed with
# nixos-anywhere; see the README.
{ inputs, ... }:
{
  hosts.ovh-1 = {
    system = "x86_64-linux";
    address = "100.88.40.104";
    module =
      { modulesPath, ... }:
      {
        imports = [
          (modulesPath + "/profiles/qemu-guest.nix")
          inputs.disko.nixosModules.disko
        ];

        boot.initrd.availableKernelModules = [
          "ata_piix"
          "uhci_hcd"
          "virtio_pci"
          "virtio_scsi"
          "sd_mod"
          "sr_mod"
        ];

        # The VPS boots with BIOS, so GRUB goes in a BIOS boot partition; disko
        # installs it on this disk.
        boot.loader.grub.enable = true;
        disko.devices.disk.main = {
          type = "disk";
          device = "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi0-0-0-0";
          content = {
            type = "gpt";
            partitions = {
              bios = {
                size = "1M";
                type = "EF02";
              };
              root = {
                size = "100%";
                content = {
                  type = "filesystem";
                  format = "ext4";
                  mountpoint = "/";
                };
              };
            };
          };
        };

        # OVH hands out IPv4 over DHCP; IPv6 is static, with its gateway outside
        # the /128.
        networking.useNetworkd = true;
        systemd.network.networks."10-wan" = {
          matchConfig.Name = "en*";
          networkConfig.DHCP = "ipv4";
          address = [ "2001:41d0:404:200::6ea7/128" ];
          routes = [
            {
              Gateway = "2001:41d0:404:200::1";
              GatewayOnLink = true;
            }
          ];
        };

        system.stateVersion = "26.05";
      };
  };
}
