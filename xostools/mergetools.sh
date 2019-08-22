#!/bin/bash

mergeUpstream() {
  pushd $(gettop)
  bash -i "$(gettop)/external/xos/xostools/scripts/merge_upstream.sh" $@
  popd
}
