#!/usr/bin/env bash
#
# Build the pinned source — which fails when its hash is wrong — and check that
# the wrapper still evaluates, without paying for the FHS environment build.
set -euo pipefail

source "$(dirname "$0")/config.sh"
source "$(dirname "$0")/common.sh"

version="$(pinned_version)"
if [ -z "$version" ]; then
  echo "nothing is pinned, nothing to verify"
  exit 0
fi

echo "Building ${version}"
nix build --no-link ".#asar"
nix build --dry-run ".#default"
