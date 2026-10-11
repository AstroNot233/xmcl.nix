#!/usr/bin/env bash
#
# Work out which version should be pinned: the newest one upstream has, a
# prerelease or not. Writes it as `version` to $GITHUB_OUTPUT; nothing to move
# to keeps the version already pinned, so a failed lookup never drops a pin.
#
# Requires GITHUB_TOKEN when it is available: the anonymous rate limit is per
# IP, and a runner shares its IP.
set -euo pipefail

source "$(dirname "$0")/config.sh"
source "$(dirname "$0")/common.sh"

# Wide enough that the newest release does not fall out of the window during a
# stretch of prereleases.
releases=""
if [ -n "${GITHUB_TOKEN:-}" ]; then
  releases="$(curl -fsSL -H "Authorization: Bearer ${GITHUB_TOKEN}" \
    "${API_URL}/releases?per_page=100" 2>/dev/null)" || releases=""
else
  releases="$(curl -fsSL "${API_URL}/releases?per_page=100" 2>/dev/null)" || releases=""
fi

if [ -z "$releases" ] || [ "$releases" = "null" ] || [ "$releases" = "[]" ]; then
  echo "::warning::the releases API call returned nothing, keeping the pinned version"
  releases=""
fi

pinned="$(pinned_version)"

if [ -z "$releases" ]; then
  # A failed call must not drop a pin; the next run picks the release up.
  version="$pinned"
else
  # Candidates in API order, newest publication first, one "rel|pre <version>"
  # line each. A prerelease is a candidate like any other: this flake follows
  # the newest version upstream offers, and an older one stays reachable
  # through its own tag.
  candidates="$(jq -r --arg fmt "$VERSION_FMT" '
    .[] | select(.draft | not) | .tag_name as $tag
    | select($tag | test("^v" + $fmt + "$"))
    | "\(if .prerelease then "pre" else "rel" end) \($tag | ltrimstr("v"))"
  ' <<< "$releases")" || candidates=""

  if [ -z "$candidates" ]; then
    # Nothing to move to; never read that as "the release is gone".
    echo "::warning::no release upstream is a plain version, keeping the pinned '${pinned:-none}'"
    version="$pinned"
  else
    # The newest version is the one with the highest M.m.p. `sort -V` orders
    # those correctly, which it does not do for a whole version: it sorts
    # 0.72.0-rc.1 after 0.72.0.
    base="$(cut -d' ' -f2 <<< "$candidates" | sed 's/-.*//' | sort -V | tail -n1)"
    # A tie on M.m.p goes to the stable release, so 0.72.0 wins over 0.72.0-rc.1
    # no matter which of the two upstream published last; among prereleases it
    # goes to the API order, i.e. to the newest publication.
    version="$(awk -v b="$base" '
      { v = $2; sub(/-.*/, "", v) }
      v != b { next }
      $1 == "rel" && rel == "" { rel = $2 }
      $1 == "pre" && pre == "" { pre = $2 }
      END { print (rel != "" ? rel : pre) }
    ' <<< "$candidates")"

    # Never go backwards: upstream occasionally tags a patch on an older line,
    # or drops a release, which would silently downgrade the pin and the tag.
    base_pinned="${pinned%%-*}"
    if [ -n "$pinned" ] && [ "${version%%-*}" != "$base_pinned" ] &&
      [ "$(printf '%s\n%s\n' "${version%%-*}" "$base_pinned" | sort -V | tail -n1)" = "$base_pinned" ]; then
      echo "::warning::upstream is at ${version}, older than the pinned ${pinned}; keeping the pin"
      version="$pinned"
    fi
  fi
fi

echo "pinned '${pinned:-none}', upstream '${version:-none}'"
printf 'version=%s\n' "$version" >> "$GITHUB_OUTPUT"
