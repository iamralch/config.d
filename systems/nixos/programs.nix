{ pkgs, ... }: {
  programs = {
    dconf.enable = true;
    nix-ld = {
      enable = true;
      libraries = with pkgs; [
        stdenv.cc.cc.lib
        zlib
        openssl
        curl
        icu
        libgcc
      ];
    };
  };
}
