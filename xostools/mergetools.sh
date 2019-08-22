#!/bin/bash

mergeUpstream() {
  pushd $(gettop)
  bash -i "external/xos/xostools/scripts/merge_upstream.sh" $@
  popd
}

mergeAospUpstream() {
  pushd $(gettop)
  bash -i "external/xos/xostools/scripts/merge_aosp.sh" $@
  popd
}
