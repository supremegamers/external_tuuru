#!/bin/bash

mergeUpstream() {
    TOP="$(gettop)" bash -i "$(gettop)/external/xos/xostools/scripts/merge_upstream.sh" $@
}

mergeAospUpstream() {
    TOP="$(gettop)" bash -i "$(gettop)/external/xos/xostools/scripts/merge_aosp.sh" $@
}
