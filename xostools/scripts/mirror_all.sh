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
while read path; do
    echo "$path"
    pushd $path

    if [ "$(git rev-parse --is-shallow-repository)" == "true" ]; then
        echo "Shallow repository detected, skipping"
        popd
        continue
    fi

    addXos || :
    addXosGithub || :
    git branch -r --list 'xos/*' | awk '{ print $1 }' | cut -d '/' -f2 | xargs -i git push -f xosgh 'xos/{}:refs/heads/{}' || :

    echo
    popd
done < <(xmlstarlet sel -t -v '/manifest/project/@path' $snippet)


echo "Everything done."

