#!/bin/bash

#
# Copyright (C) 2016-2017 The halogenOS Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


function tuuru_help_play() {

cat <<EOF
Usage: play <target> [lunch target] [instrument] [nohype]

Targets:
    live            "Live on stage" (make bandori)
    instrument      "Play" only a specific "instrument" (Build only a specific module)
    instrument-list "Play" multiple "instruments" (Build multiple modules)
    mm              "Plays" using mmma. Useful for frameworks or "instruments"
                    which you want to "play" using mmma/mmm/

nohype: Use this option to "play" directly without "hype" (skip clean before build)
        This is not accepted on "instrument-list"

You have to specify the lunch target if you haven't lunched yet.
EOF

}

function tuuru_build_no_target_device() {

cat <<EOF
No target device specified and \$TARGET_DEVICE is
undefined
EOF

}

function tuuru_help_reporesync() {

cat <<EOF
Usage: reporesync <option> [repository path] [repository name] [low]

Options:
    full            Full resync: delete the whole source tree, do a sync and
                    fully resync local tree

Example: reporesync packages/apps/Settings android_packages_apps_Settings
            This removes packages/apps/Settings and the repository including
            object files and project files.

         reporesync full
            This does a sync and resyncs the local work tree. Deletes everything
            except .repo and does a sync.

EOF

}

return 0
