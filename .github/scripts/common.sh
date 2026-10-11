#!/usr/bin/env bash
#
# Shared helpers for the update scripts. Source config.sh first: the paths and
# the system list all come from there.

# A hash that cannot match anything, used to make nix report the real one when
# a version is pinned for the first time.
export FAKE_HASH="sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="

# Systems, one per line, in config order.
system_names() {
  local -a names
  read -ra names <<< "$SYSTEMS"
  printf '%s\n' "${names[@]}"
}

# Version pinned in sources.json, empty when nothing is pinned at all.
pinned_version() {
  jq -r '.version // empty' "$SOURCES_FILE"
}

# Version the resolve job settled on, empty when upstream has nothing to pin.
# VERSION is handed over by the workflow.
resolved_version() {
  printf '%s' "${VERSION:-}"
}

# Hash pinned for a system, empty when missing.
pinned_hash() {
  jq -r --arg s "$1" '.hash[$s] // empty' "$SOURCES_FILE"
}

# Upstream release page of a version.
release_url() {
  printf '%s/tag/v%s' "$RELEASE_URL" "$1"
}

# Upstream release asset for a version and one system.
asset_url() {
  local version="$1" asset="$2"
  printf '%s/download/v%s/app-%s-%s.asar.gz' "$RELEASE_URL" "$version" "$version" "$asset"
}

# Write sources.json through jq, atomically.
sources_update() {
  jq "$@" "$SOURCES_FILE" > sources.json.new
  mv sources.json.new "$SOURCES_FILE"
}
