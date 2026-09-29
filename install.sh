#!/bin/sh
# Installs (or updates) the humangate command, and the built-in tools in
# ~/.humangate/built-in-tools/ - which it owns, replacing them so they
# stay current. Your own tools go in ~/.humangate/user-tools/, which it never
# touches and which overrides a built-in tool of the same name:
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
base_url="https://raw.githubusercontent.com/$repo/$ref"
url="$base_url/bin/humangate"
tools_dir="$HOME/.humangate/built-in-tools"

fail() {
  echo "humangate install: $*" >&2
  exit 1
}

command -v python3 >/dev/null 2>&1 || fail "python3 (3.8 or newer) is required"
python3 -c 'import sys; sys.exit(sys.version_info < (3, 8))' || fail "python3 3.8 or newer is required"

command -v curl >/dev/null 2>&1 || command -v wget >/dev/null 2>&1 || fail "curl or wget is required"

download() { # <url> <file>
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$1" -o "$2" || fail "couldn't download $1"
  else
    wget -qO "$2" "$1" || fail "couldn't download $1"
  fi
}

mkdir -p "$bin_dir" "$tools_dir"
tmp=$(mktemp "$bin_dir/.humangate.XXXXXX")
tmp_tool=$(mktemp "$tools_dir/.tool.XXXXXX")
trap 'rm -f "$tmp" "$tmp_tool"' EXIT

download "$url" "$tmp"
head -n 1 "$tmp" | grep -q '^#!/usr/bin/env python3' || fail "$url doesn't look like humangate"

chmod 755 "$tmp"
mv "$tmp" "$bin_dir/humangate"
echo "Installed $("$bin_dir/humangate" version) to $bin_dir/humangate"

download "$base_url/tools/index" "$tmp_tool"
names=$(grep -v '^#' "$tmp_tool" || true)
[ -n "$names" ] || fail "no built-in tools listed in $base_url/tools/index"
installed=""
set -f # the names are split on whitespace, never expanded as globs
for name in $names; do
  case "$name" in
    [!A-Za-z0-9]* | *[!A-Za-z0-9._-]*) fail "not a tool name in the index: '$name'" ;;
  esac
  download "$base_url/tools/$name" "$tmp_tool"
  head -n 1 "$tmp_tool" | grep -q '^#!' || fail "$base_url/tools/$name doesn't look like a script"
  chmod 755 "$tmp_tool"
  mv "$tmp_tool" "$tools_dir/$name"
  tmp_tool=$(mktemp "$tools_dir/.tool.XXXXXX")
  installed="$installed $name"
done
set +f
# Tools no longer listed are gone from the repository too.
for path in "$tools_dir"/*; do
  [ -f "$path" ] || continue
  case "$installed " in
    *" ${path##*/} "*) ;;
    *) rm -f "$path" ;;
  esac
done
echo "Built-in tools in $tools_dir:$installed"
[ ! -d "$HOME/.humangate/tools" ] ||
  echo "Note: ~/.humangate/tools/ isn't read any more - move tools you wrote yourself to ~/.humangate/user-tools/, and delete copies of the built-in ones."

command -v git >/dev/null 2>&1 ||
  echo "Note: git isn't installed here - humangate needs it to run (to find the project and check its git config)."

case ":$PATH:" in
  *":$bin_dir:"*) ;;
  *) echo "Add $bin_dir to your PATH to run it as 'humangate'." ;;
esac
