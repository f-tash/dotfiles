#!/bin/sh
# Build from a private snapshot, never by staging machine-local files.
set -eu
cd "$(dirname "$0")"

mode=${1:-switch}
if [ "$#" -gt 1 ]; then
  echo 'Usage: ./apply.sh [build|switch]' >&2
  exit 2
fi
case "$mode" in
  build|switch) ;;
  *) echo 'Usage: ./apply.sh [build|switch]' >&2; exit 2 ;;
esac

if [ ! -f local.nix ]; then
  echo 'Create local.nix from local.nix.example before building or switching.' >&2
  exit 1
fi
if [ "$mode" = switch ] && { [ "$(uname -s)" != Darwin ] || [ "$(uname -m)" != arm64 ]; }; then
  echo 'Switch is supported only on Apple Silicon macOS.' >&2
  exit 1
fi

umask 077
snapshot=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles.XXXXXXXX")
trap 'rm -rf "$snapshot"' 0
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

# Copy working-tree contents of tracked files, including staged new files.
# Separate steps preserve failures without relying on non-POSIX pipefail.
git ls-files -z > "$snapshot/files"
tar -cf "$snapshot/source.tar" --null -T "$snapshot/files"
mkdir "$snapshot/source"
tar -xf "$snapshot/source.tar" -C "$snapshot/source"
for f in local.nix private.nix; do
  if [ -f "$f" ]; then
    cp -p "$f" "$snapshot/source/$f"
  fi
done
flake="path:$snapshot/source"

if [ "$mode" = switch ]; then
  configured_user=$(nix eval --no-update-lock-file --impure --raw \
    "$flake#homeConfigurations.default.config.home.username")
  configured_home=$(nix eval --no-update-lock-file --impure --raw \
    "$flake#homeConfigurations.default.config.home.homeDirectory")
  if [ "$configured_user" != "$(id -un)" ] || [ "$configured_home" != "$HOME" ]; then
    echo 'Configured username/home does not match the current user. Refusing to switch.' >&2
    exit 1
  fi
fi

# --impure permits the optional private module's external inputs.
# Both the launcher and its build must refuse implicit lock-file updates.
nix run --no-update-lock-file "$flake#home-manager" -- \
  "$mode" --flake "$flake#default" --impure --no-update-lock-file
