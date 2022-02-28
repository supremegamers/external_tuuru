#!/bin/bash

set -e

cd $TOP

# Write a temporary manifest first.
repo manitest > .manifest.swp
snippet="$TOP/.manifest.swp"

if [[ "$2" == "--"* ]]; then
    echo "Specify positional arguments after options, for example --no-reset foo"
    exit 2
fi

if [[ "$1" == "--help" ]]; then
    echo "Optional: First non-flag argument is tag"
    echo "Optional: Specify env var tag_to_push_suffix"
fi

source build/envsetup.sh

if [ "$1" != "--no-reset" ]; then
    echo "Warning: This will perform a reporeset and a reposync to make sure everything is up to date before doing the merges"
    echo "If you do not want that to happen, abort now using CTRL+C and use the parameter --no-reset"
    echo "Otherwise, just confirm with ENTER"
    read
    echo
    reporeset
    reposync fast
else
    shift
fi

cd $TOP

repo_revision=$(xmlstarlet sel -t -v "/manifest/remote[@name='yuki-no-git']/@revision" $snippet | sed -re 's/^refs\/heads\/(.*)$/\1/')
# provide suffix in env
tag_to_push="${repo_revision}-$(date '+%Y%m%d_%H%M%S_%Z_%s')${tag_to_push_suffix}"
if [ ! -z "$1" ]; then
    tag_to_push="$1${tag_to_push_suffix}"
fi
while read path; do
    echo "$path"
    pushd $path

    if [ "$(git rev-parse --is-shallow-repository)" == "true" ]; then
        echo "Shallow repository detected, unshallowing first"
        git fetch --unshallow
    fi

    git tag "${tag_to_push}"
    addYuki
    git push yuki-no-git "${tag_to_push}"

    echo
    popd
done < <(xmlstarlet sel -t -v '/manifest/project[@merge-aosp="true"]/@path' $snippet)


echo "Everything done."

# Remove swap file
rm $TOP/.manifest.swp
