#!/usr/bin/env bash
#
# Commit the sources and the readme when they moved, then push them together
# with the tag of the version being packaged. A run that changed nothing commits
# nothing.
set -euo pipefail

source "$(dirname "$0")/config.sh"
source "$(dirname "$0")/common.sh"

git add "$SOURCES_FILE" "$README_FILE"
if git diff --cached --quiet -- "$SOURCES_FILE" "$README_FILE"; then
  echo "nothing to commit"
  exit 0
fi

version="$(pinned_version)"
if [ -z "$version" ]; then
  echo "::error::${SOURCES_FILE} has no version to tag"
  exit 1
fi

git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
# -c/--no-gpg-sign: a checkout with commit.gpgSign or tag.gpgSign set (this is
# the case when the script is replayed locally) would otherwise sign with
# somebody's key and stop for a passphrase.
git commit --no-gpg-sign -m "v${version}"

# Upstream tags its releases as v<version>, so tag the same way and the flake
# can be pinned as ...?ref=v<version>. A version that is already tagged is moved
# along when upstream replaced the artifact behind it.
#
# The CI checkout has no tags (actions/checkout fetches with --no-tags), so ask
# the remote: pushing an existing tag without force fails the atomic push.
if git ls-remote --exit-code --refs origin "refs/tags/v${version}" >/dev/null 2>&1; then
  git -c tag.gpgSign=false tag -f -a "v${version}" -m "xmcl ${version}"
  ref="+refs/tags/v${version}"
else
  git -c tag.gpgSign=false tag -a "v${version}" -m "xmcl ${version}"
  ref="refs/tags/v${version}"
fi

# One atomic push: the branch and its tag land together or not at all.
git push --atomic origin HEAD "$ref"
