#!/bin/bash

set -e

if [ "$1" != "--no-reset" ]; then
  echo "Warning: This will perform a reporeset and a reposync to make sure everything is up to date before doing the merges"
  echo "If you do not want that to happen, abort now using CTRL+C and use the parameter --no-reset"
  echo "Otherwise, just confirm with ENTER"
  read
  echo
fi

source build/envsetup.sh

if [ "$1" != "--no-reset" ]; then
  reporeset
  reposync fast
fi

echo "Generating temporary manifest file"
repo manifest > full-manifest.xml

while read path; do
  echo "$path"
  repo_path="$path"
  repo_upstream_full=$(xmlstarlet sel -t -v "/manifest/project[@path='$path']/@upstream" full-manifest.xml)
  repo_upstream=$(echo "$repo_upstream_full" | cut -d '|' -f1)
  echo "Upstream: $repo_upstream"
  repo_upstream_rev=$(echo "$repo_upstream_full" | cut -d '|' -f2)
  echo "Upstream revision: $repo_upstream_rev"
  repo_remote=$(xmlstarlet sel -t -v "/manifest/project[@path='$path']/@remote" full-manifest.xml)

  pushd $path

  echo "Setting upstream remote"
  if ! git ls-remote upstream >/dev/null 2>/dev/null; then
    git remote add upstream $repo_upstream
  else
    git remote set-url upstream $repo_upstream
  fi

  if [ "$(git rev-parse --is-shallow-repository)" == "true" ]; then
    echo "Shallow repository detected, unshallowing first"
    git fetch --unshallow $repo_remote
  fi

  echo "Fetching upstream"
  git fetch upstream
  echo "Merging upstream"
  git merge upstream/$repo_upstream_rev

  if hash xg >/dev/null 2>/dev/null; then
    xg dpush
  fi
  popd

  echo
done < <(xmlstarlet sel -t -v '/manifest/project[@upstream]/@path' full-manifest.xml)

echo "Deleting temporary manifest file"
rm -f full-manifest.xml

echo "Everything done."
