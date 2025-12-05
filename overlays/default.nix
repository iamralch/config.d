# This configures nixpkgs.overlays to include our overlays/ directory.
let
  path = ../overlays;
in
with builtins;
map (n: import (path + ("/" + n))) (
  filter (
    n:
    n != "default.nix"
    # Skip default.nix to avoid recursion
    && (match ".*\\.nix" n != null || pathExists (path + ("/" + n + "/default.nix")))
  ) (attrNames (readDir path))
)
