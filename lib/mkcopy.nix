# Helper to copy a file (instead of symlink) for devcontainer bind mount compatibility
# Usage: mkCopy lib src dest
# src is relative to PWD (repo root)

{ lib }:

let
  cwd = builtins.getEnv "PWD";
in
src: dest: lib.hm.dag.entryAfter [ "writeBoundary" ] ''
  mkdir -p "$(dirname "${dest}")"
  cp -f "${cwd}/${src}" "${dest}"
''
