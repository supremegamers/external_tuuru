#!/bin/bash

mergeUpstream() {
    TOP="$(gettop)" bash -i "$(gettop)/external/xos/xostools/scripts/merge_upstream.sh" $@
}

mergeAospUpstream() {
    TOP="$(gettop)" bash -i "$(gettop)/external/xos/xostools/scripts/merge_aosp.sh" $@
}

createSnapshot() {
    TOP="$(gettop)" bash -i "$(gettop)/external/xos/xostools/scripts/create_snapshot.sh" $@
}

mirrorAll() {
    TOP="$(gettop)" bash -i "$(gettop)/external/xos/xostools/scripts/mirror_all.sh" $@
}

