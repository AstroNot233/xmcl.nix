#!/usr/bin/env bash
#
# One system: pin the resolved version, build it, and read the hash nix asks for
# out of the mismatch report; a build without a mismatch means the pinned hash
# is still the right one. Writes hash.env with one "<system> <hash>" line per
# hash that has to change.
#
# Requires SYSTEM and VERSION.
set -euo pipefail

source "$(dirname "$0")/config.sh"
source "$(dirname "$0")/common.sh"

: > hash.env

version="$(resolved_version)"
if [ -z "$version" ]; then
  echo "nothing released upstream, nothing to pin"
  exit 0
fi

# The entry has to exist with a hash for this system, otherwise nix throws
# instead of reporting the hash it wants.
sources_update --arg v "$version" --arg s "$SYSTEM" --arg fake "$FAKE_HASH" '
  .version = $v | .hash = ((.hash // {}) | .[$s] = (.[$s] // $fake))
'

if log=$(nix build ".#asar" 2>&1); then
  echo "hash unchanged (${version}, ${SYSTEM})"
  exit 0
fi

got=$(printf '%s\n' "$log" | sed -n 's/.*got: *//p' | tail -n1)
if [ -z "$got" ]; then
  printf '%s\n' "$log"
  echo "::error::no hash mismatch reported on ${SYSTEM}"
  exit 1
fi

# The hash was scraped from a failed build, so prove it: pin it and build
# again. This is the only check the other system's hash ever gets, since no
# runner can build for it.
sources_update --arg s "$SYSTEM" --arg h "$got" '.hash = ((.hash // {}) | .[$s] = $h)'
if ! nix build ".#asar" >/dev/null 2>&1; then
  echo "::error::the hash reported on ${SYSTEM} does not verify"
  exit 1
fi

echo "hash is now ${got}"
printf '%s %s\n' "$SYSTEM" "$got" > hash.env
