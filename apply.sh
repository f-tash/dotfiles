#!/bin/sh
# Stage local.nix and private.nix temporarily so the pure flake evaluator can
# see them (Nix's git filter excludes untracked/gitignored files). The trap
# restores git state on exit. private.nix imports an absolute path outside the
# flake tree, so the build runs with --impure.
set -e
cd "$(dirname "$0")"
staged=""
for f in local.nix private.nix; do
  if [ -f "$f" ]; then
    git add -f "$f"
    staged="$staged $f"
  fi
done
# shellcheck disable=SC2064
trap "git restore --staged$staged 2>/dev/null || true" EXIT
nix run home-manager/master -- switch --flake .#default --impure
