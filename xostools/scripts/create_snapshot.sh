#!/bin/bash

set -e

cd $TOP

snippet="$TOP/.repo/manifests/snippets/XOS.xml"

if [[ "$2" == "--"* ]]; then
    echo "Specify positional arguments after options, for example --no-reset foo"
    exit 2
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

repo_revision=$(xmlstarlet sel -t -v "/manifest/remote[@name='XOS']/@revision" $snippet | sed -re 's/^refs\/heads\/(.*)$/\1/')
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
    if hash xg >/dev/null 2>/dev/null; then
        xg a 2>/dev/null || :
        git push gerrit "${tag_to_push}"
    fi

    echo
    popd
done < <(xmlstarlet sel -t -v '/manifest/project[@merge-aosp="true"]/@path' $snippet)


echo "Everything done."

