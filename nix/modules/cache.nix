# Every host substitutes from the Pi's binary cache (nix/hosts/piquel-pi/cache.nix)
# before building, after cache.nixos.org. While the Pi is unreachable, Nix
# skips it.
{
  flake.nixosModules.cache = {
    nix.settings = {
      extra-substituters = [ "https://piquel-pi.tailfcb6ab.ts.net" ];
      extra-trusted-public-keys = [ "piquel-pi-1:bKIz75gwV7RfJ6uT1YI+fUYbGk1uptOl9Vlu/jR+r0w=" ];
    };
  };
}
