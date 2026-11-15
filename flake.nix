{
  description = "NixOS configuration for the operator's machines";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-26.05";
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";

    nixos-raspberrypi = {
      url = "github:nvmd/nixos-raspberrypi/main";
      # Its own nixpkgs is the one its binary cache has Pi kernels for.
      # Following ours would build them from source, under emulation.
      #inputs.nixpkgs.follows = "nixpkgs";
    };
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    piqueld.url = "github:sourceorigin-dev/piqueld";
  };

  nixConfig = {
    extra-substituters = [
      "https://nixos-raspberrypi.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
    ];
  };

  # Every file under ./nix is a flake-parts module, except paths containing `/_`
  # (plain NixOS modules such as hardware configurations).
  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      imports = [ (inputs.import-tree ./nix) ];
      perSystem =
        { pkgs, inputs', ... }:
        {
          formatter = pkgs.nixfmt-tree;
          devShells.default = pkgs.mkShell {
            packages = [
              # nixpkgs' build, cached and the same `activate` the hosts run.
              pkgs.deploy-rs
              pkgs.nixos-anywhere
              inputs'.agenix.packages.default
            ];
          };
        };
    };
}
