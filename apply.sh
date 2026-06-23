#!/bin/sh
# Stage local.nix temporarily so the pure flake evaluator can see it (Nix's
# git filter excludes untracked files). The trap restores git state on exit.
set -e
cd "$(dirname "$0")"
if [ -f local.nix ]; then
  git add -f local.nix
  trap 'git restore --staged local.nix 2>/dev/null || true' EXIT
fi
nix run home-manager/master -- switch --flake .#default
