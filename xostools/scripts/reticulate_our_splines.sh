#!/bin/bash

set -e

pushd $TOP

source build/envsetup.sh

if [ -z "$ROM_REVISION" ]; then
  ROM_REVISION="$ROM_VERSION"
fi

has_createxos=true
if ! type createXos >/dev/null 2>/dev/null; then
  echo -e "\033[1m;Note: createXos not found, repositories won't be created if missing! \033[0m"
  has_createxos=false
fi

echo "Generating temporary manifest file"
repo manifest > full-manifest.xml
echo "Generating repository list"
typeset -a list=( $(xmlstarlet sel -t -v '/manifest/project[@upstream]/@path' full-manifest.xml) )

for path in ${list[@]}; do
  echo
  echo "$path"
  repo_path="$path"
  repo_upstream_full=$(xmlstarlet sel -t -v "/manifest/project[@path='$path']/@upstream" full-manifest.xml)
  repo_upstream=$(echo "$repo_upstream_full" | cut -d '|' -f1)
  echo "Upstream: $repo_upstream"
  repo_upstream_rev=$(echo "$repo_upstream_full" | cut -d '|' -f2)
  echo "Upstream revision: $repo_upstream_rev"
  repo_remote=$(xmlstarlet sel -t -v "/manifest/project[@path='$path']/@remote" full-manifest.xml || :)
  echo "Remote: $repo_remote"
  repo_revision=$(xmlstarlet sel -t -v "/manifest/project[@path='$path']/@revision" full-manifest.xml || :)
  if [ -z "$repo_revision" ]; then
    echo -n "(from remote definition) "
    repo_revision=$(xmlstarlet sel -t -v "/manifest/remote[@name='$repo_remote']/@revision" full-manifest.xml || :)
  fi
  short_revision=${repo_revision/refs\/heads\//}
  echo "Revision: $repo_revision ($short_revision)"

  if [ -z "$repo_revision" ]; then
    if [ -z "$ROM_REVISION" ]; then
      echo -e "\033[1mWarning: unable to determine revision and ROM_REVISION or ROM_VERSION not set, skipping! \033[0m"
      popd
      continue
    else
      echo -e "\033[1mWarning: unable to determine revision, defaulting to $ROM_REVISION \033[0m"
      repo_revision="$ROM_REVISION"
    fi
  fi

  mkdir -p $path
  pushd $path

  if [ ! -d .git ]; then
    git init
  else
    if git ls-remote XOS >/dev/null 2>/dev/null; then
      echo "Skipping $repo_path, already there"
      popd
      continue
    fi
  fi

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
  echo "Checking out $repo_upstream_rev -> $short_revision"
  git checkout upstream/$repo_upstream_rev -B $short_revision
  $has_createxos && echo "Creating repository (if it doesn't exist)" && createXos || :

  if hash xg >/dev/null 2>/dev/null; then
    echo "Pushing"
    xg dpush || echo "dpush returned non-zero!"
  fi
  popd

done

echo
echo "Deleting temporary manifest file"
rm -f full-manifest.xml

popd

echo "Everything done."
