#!/bin/bash

mergeUpstream() {
    TOP="$(gettop)" bash -i "$(gettop)/external/tuuru/kasumi-no-tuuru/scripts/merge_upstream.sh" $@
}

mergeAospUpstream() {
    TOP="$(gettop)" bash -i "$(gettop)/external/tuuru/kasumi-no-tuuru/scripts/merge_aosp.sh" $@
}

createSnapshot() {
    TOP="$(gettop)" bash -i "$(gettop)/external/tuuru/kasumi-no-tuuru/scripts/create_snapshot.sh" $@
}
