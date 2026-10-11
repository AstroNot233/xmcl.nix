#!/usr/bin/env bash
#
# Rewrite the readme table between the markers from sources.json; everything
# outside the markers is hand written.
set -euo pipefail

source "$(dirname "$0")/config.sh"
source "$(dirname "$0")/common.sh"

block="$(
  {
    echo
    header="| Ref |"
    align="| --- |"
    while read -r system; do
      header="${header} \`${system}\` |"
      align="${align} :---: |"
    done < <(system_names)
    echo "${header} Updated |"
    echo "${align} --- |"

    version="$(pinned_version)"
    if [ -z "$version" ]; then
      row="| — |"
      while read -r system; do row="${row} — |"; done < <(system_names)
      echo "${row} — |"
    else
      row="| [\`v${version}\`]($(release_url "$version")) |"
      while read -r system; do
        hash="$(pinned_hash "$system")"
        if [ -n "$hash" ]; then
          row="${row} ✅ [\`${hash:7:8}…\`]($(asset_url "$version" "$(system_asset "$system")")) |"
        else
          row="${row} — |"
        fi
      done < <(system_names)
      echo "${row} $(jq -r '.updated // "—"' "$SOURCES_FILE") |"
    fi
  }
)"

export BLOCK="$block"

# Without both markers the rewrite below would drop everything that follows the
# opening one.
grep -qF -- "$MARKER_BEGIN" "$README_FILE" && grep -qF -- "$MARKER_END" "$README_FILE" || {
  echo "::error::${README_FILE} is missing one of the packaged markers"
  exit 1
}

awk '
  index($0, ENVIRON["MARKER_BEGIN"]) == 1 { print; print ENVIRON["BLOCK"]; print ""; inside = 1; next }
  index($0, ENVIRON["MARKER_END"]) == 1 { inside = 0 }
  !inside { print }
' "$README_FILE" > readme.new
mv readme.new "$README_FILE"

git diff -- "$README_FILE"
