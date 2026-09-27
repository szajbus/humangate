#!/bin/sh
# Installs (or updates) the humangate command:
#
#   curl -fsSL https://raw.githubusercontent.com/szajbus/humangate/main/install.sh | sh
#
# Settings (environment variables):
#   HUMANGATE_BIN_DIR  where to put it (default: ~/.local/bin)
#   HUMANGATE_REF      branch or tag to install (default: main)
set -eu

repo="szajbus/humangate"
ref="${HUMANGATE_REF:-main}"
bin_dir="${HUMANGATE_BIN_DIR:-$HOME/.local/bin}"
url="https://raw.githubusercontent.com/$repo/$ref/bin/humangate"

fail() {
  echo "humangate install: $*" >&2
  exit 1
}

command -v python3 >/dev/null 2>&1 || fail "python3 (3.8 or newer) is required"
python3 -c 'import sys; sys.exit(sys.version_info < (3, 8))' || fail "python3 3.8 or newer is required"

mkdir -p "$bin_dir"
tmp=$(mktemp "$bin_dir/.humangate.XXXXXX")
trap 'rm -f "$tmp"' EXIT

if command -v curl >/dev/null 2>&1; then
  curl -fsSL "$url" -o "$tmp" || fail "couldn't download $url"
elif command -v wget >/dev/null 2>&1; then
  wget -qO "$tmp" "$url" || fail "couldn't download $url"
else
  fail "curl or wget is required"
fi
head -n 1 "$tmp" | grep -q '^#!/usr/bin/env python3' || fail "$url doesn't look like humangate"

chmod 755 "$tmp"
mv "$tmp" "$bin_dir/humangate"
echo "Installed $("$bin_dir/humangate" version) to $bin_dir/humangate"

command -v git >/dev/null 2>&1 ||
  echo "Note: git isn't installed here - humangate needs it to run (to find the project and check its git config)."

case ":$PATH:" in
  *":$bin_dir:"*) ;;
  *) echo "Add $bin_dir to your PATH to run it as 'humangate'." ;;
esac
