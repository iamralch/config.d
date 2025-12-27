# Helper to create symlink to repo files (bypasses Nix store)
# Usage: mkSymlink lib src dest
# src is relative to PWD (repo root)

{ lib }:

let
  cwd = builtins.getEnv "PWD";
in
src: dest: lib.hm.dag.entryAfter [ "writeBoundary" ] ''
  mkdir -p "$(dirname "${dest}")"
  ln -sfn "${cwd}/${src}" "${dest}"
''
