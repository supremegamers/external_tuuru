#!/bin/bash

mergeUpstream() {
  pushd $(gettop)
  $(gettop)/external/xos/xostools/scripts/merge_upstream.sh $@
  popd
}
