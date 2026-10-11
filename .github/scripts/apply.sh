#!/usr/bin/env bash
#
# Apply what the resolve and hash jobs found: the version, the hashes that
# changed, and an update date for a version that moved.
#
# Requires VERSION, HASHES_DIR and GITHUB_OUTPUT.
set -euo pipefail

source "$(dirname "$0")/config.sh"
source "$(dirname "$0")/common.sh"

today="$(date -u +%F)"
moved=""

version="$(resolved_version)"
pinned="$(pinned_version)"

if [ -z "$version" ]; then
  # resolve falls back to the pin whenever the API call fails, so this only
  # happens while nothing is pinned at all.
  if [ -n "$pinned" ]; then
    echo "::warning::upstream has nothing to pin, keeping ${pinned}"
  fi
elif [ "$version" != "$pinned" ]; then
  echo "${pinned:-none} -> ${version}"
  sources_update --arg v "$version" '.version = $v'
  moved=1
fi

shopt -s nullglob
files=("$HASHES_DIR"/*/hash.env)
[ "${#files[@]}" -eq "$(system_names | wc -l)" ] || {
  echo "::error::expected one hash.env per system, found ${#files[@]}: ${files[*]}"
  exit 1
}

# Write every hash by system. A plain string replacement would be ambiguous
# here: a version pinned for the first time carries a placeholder, and that
# placeholder is the same for both systems.
for file in "${files[@]}"; do
  while read -r system got; do
    [ -n "$system" ] || continue
    [ -n "$(pinned_version)" ] || {
      echo "::error::a hash was reported with no pinned version"
      exit 1
    }
    sources_update --arg s "$system" --arg h "$got" '.hash = ((.hash // {}) | .[$s] = $h)'
    [ "$(pinned_hash "$system")" = "$got" ] || {
      echo "::error::cannot pin ${got} on ${system}"
      exit 1
    }
    echo "${system}: hash is now ${got}"
    moved=1
  done < "$file"
done

if [ -n "$moved" ]; then
  sources_update --arg d "$today" '.updated = $d'
  echo "updated ${today}"
fi

if git diff --quiet -- "$SOURCES_FILE"; then
  echo "sources.json is up to date"
  echo "changed=false" >> "$GITHUB_OUTPUT"
else
  git diff -- "$SOURCES_FILE"
  echo "changed=true" >> "$GITHUB_OUTPUT"
fi
