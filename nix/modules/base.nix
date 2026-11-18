# Settings shared by every host: locale, shell, tools and Nix itself.
{
  flake.nixosModules.base =
    { pkgs, ... }:
    {
      time.timeZone = "Europe/Paris";
      console.keyMap = "fr";
      i18n.defaultLocale = "en_US.UTF-8";
      i18n.extraLocaleSettings = {
        LC_ADDRESS = "fr_FR.UTF-8";
        LC_IDENTIFICATION = "fr_FR.UTF-8";
        LC_MEASUREMENT = "fr_FR.UTF-8";
        LC_MONETARY = "fr_FR.UTF-8";
        LC_NAME = "fr_FR.UTF-8";
        LC_NUMERIC = "fr_FR.UTF-8";
        LC_PAPER = "fr_FR.UTF-8";
        LC_TELEPHONE = "fr_FR.UTF-8";
        LC_TIME = "fr_FR.UTF-8";
      };

      programs.zsh.enable = true;
      users.defaultUserShell = pkgs.zsh;
      # Skip zsh's first-run wizard for users without a `.zshrc`.
      system.userActivationScripts.zshrc = "touch .zshrc";

      programs.git.enable = true;
      programs.tmux.enable = true;
      environment.variables.EDITOR = "nvim";
      environment.systemPackages = with pkgs; [
        neovim
        zip
        unzip
        tree
        fd
        fzf
        file
      ];

      nix = {
        settings = {
          experimental-features = [
            "nix-command"
            "flakes"
          ];
          auto-optimise-store = true;
          # The Pi's binary cache (nix/hosts/piquel-pi/cache.nix), after
          # cache.nixos.org. While it's unreachable, `fallback` builds what
          # it would have served instead of failing, and skips it for a
          # minute. Nix retries a connection that times out, so the short
          # timeout keeps that to about half a minute.
          extra-substituters = [ "https://piquel-pi.tailfcb6ab.ts.net" ];
          extra-trusted-public-keys = [ "piquel-pi-1:bKIz75gwV7RfJ6uT1YI+fUYbGk1uptOl9Vlu/jR+r0w=" ];
          fallback = true;
          connect-timeout = 5;
        };
        gc = {
          automatic = true;
          dates = "weekly";
          options = "--delete-older-than 10d";
        };
      };
    };
}
