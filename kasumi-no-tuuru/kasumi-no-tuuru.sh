#!/bin/bash

#
# Copyright (C) 2016-2018 The halogenOS Project
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

echo -e "\033[0mincluding \033[1m\033[38;5;225mカスミ\033[0m\033[1mのツール\033[0m"

# Get the CPU count
# CPU count is either your virtual cores when using Hyperthreading
# or your physical core count when not using Hyperthreading
# Here the virtual cores are always counted, which can be the same as
# physical cores if not using Hyperthreading or a similar feature.
CPU_COUNT=$(nproc --all)
# Use 2 times the CPU count to build
THREAD_COUNT_BUILD=$(($CPU_COUNT * 2))
# Use doubled CPU count to sync (auto)
THREAD_COUNT_N_BUILD=$(($CPU_COUNT * 2))

# Save the current directory before continuing the script.
# The working directory might change during the execution of specific
# functions, which should be set back to the beginning directory
# so the user does not need to do that manually.
BEGINNING_DIR="$(pwd)"

### BASIC FUNCTIONS START

# Echo with PoPiPa color without new line
function echoxcc() {
    echo -en "\033[1;38;5;225m$@\033[0m"
}

# Echo with PoPiPa color with new line
function echoxc() {
    echoxcc "\033[1;38;5;225m$@\033[0m\n"
}

# Echo with new line and respect escape characters
function echoe() {
    echo -e "$@"
}

# Echo with line, respect escape characters and print in bold font
function echob() {
    echo -e "\033[1m$@\033[0m"
}

# Echo without new line
function echon() {
    echo -n "$@"
}

# Echo without new line and respect escape characters
function echoen() {
    echo -en "$@"
}

### BASIC FUNCTIONS END

# Import help functions
source $(gettop)/external/tuuru/kasumi-no-tuuru/kasumi-no-tuuru-help.sh

# Build function
function play() {
    buildarg="$1"
    target="$2"
    cleanarg="$3 $4"
    instrument="${cleanarg//nohype/}"
    instrument="${instrument// /}"
    cleanarg="${cleanarg/$instrument/}"
    cleanarg="${cleanarg// /}"

    # Display help if no argument passed
    if [ -z "$buildarg" ]; then
        tuuru_help_play
        return 0
    fi

    # Notify that no target device could be found
    if [ -z "$target" ]; then
        tuuru_play_no_target_device
    else
        # Handle the first argument
        case "$buildarg" in

            live | instrument | mm)
                echob "Playing live..."
                [ -z "$instrument" ] && instrument="bandori" || \
                    echo "You have decided to play $module"
                # Of course let's check the kitchen
                lunch $target
                # Clean if desired
                [[ "$cleanarg" == "nohype" ]] || make clean
                # Now start building
                echo "Using $THREAD_COUNT_BUILD threads for build."
                if [ "$buildarg" != "mm" ]; then
                    make -j$THREAD_COUNT_BUILD $instrument
                    return $?
                else
                    mmma -j$THREAD_COUNT_BUILD $instrument
                    return $?
                fi
            ;;

            instrument-list)
                local bm_result
                echob "Playing multiple instruments..."
                shift
                ALL_MODULES_TO_BUILD="$@"
                [[ "$@" == *"nohype"* ]] || make clean
                for module in $ALL_MODULES_TO_BUILD; do
                    [[ "$instrument" == "nohype" ]] && continue
                    echo
                    echob "Playing instrument $instrument"
                    echo
                    play instrument $TOOL_THIRDARG $instrument nohype
                    local bm_result=$?
                done
                echob "Finished multiple play"
                [ $bm_result -ne 0 ] && return $bm_result
            ;;

            cd_album)
              echob "Playing CD Album..."
              lunch $target
              make -j$THREAD_COUNT_BUILD iso_img
            ;;

            # Oops.
            *) echo "Unknown note route \"$TOOL_SUBARG\"." ;;

        esac
    fi
    return 0
}

# Reposync!! Laziness is taking over.
# Sync with special features and traditional repo.
function reposync() {
    # You have slow internet? You don't want to consume the whole bandwidth?
    # Same variable definition stuff as always
    REPO_ARG="$1"
    PATH_ARG="$2"
    QUIET_ARG=""
    THREADS_REPO=$THREAD_COUNT_N_BUILD
    # Automatic!
    [ -z "$REPO_ARG" ] && REPO_ARG="auto"
    # Let's decide how much threads to use
    # Self-explanatory.
    case $REPO_ARG in
        turbo)      THREADS_REPO=$(($CPU_COUNT * 10));;
        faster)     THREADS_REPO=$(($CPU_COUNT * 4)) ;;
        fast)       THREADS_REPO=$(($CPU_COUNT * 2)) ;;
        auto)                               ;;
        slow)       THREADS_REPO=$CPU_COUNT;;
        slower)     THREADS_REPO=$(echo "scale=1; $CPU_COUNT / 2 + 0.5" | bc | cut -d '.' -f1);; # + 0.5 will round
        single)     THREADS_REPO=1          ;;
        easteregg)  THREADS_REPO=384        ;; # Simao@XOS: Neil's love
        popipa)     THREADS_REPO=1407       ;; # Beru@Kasumi: 14 July, Kasumi's birth
        quiet)      QUIET_ARG="-q"          ;;
        # People might want to get some good help
        -h | --help | h | help | man | halp | idk )
            echo "Usage: reposync <speed> [path]"
            echo "Available speeds are:"
            echo -en "  turbo\n  faster\n  fast\n  auto\n  slow\n" \
                      " slower\n  single\n  easteregg\n  popipa\n\n"
            echo "Path is not necessary. If not supplied, defaults to workspace."
            return 0
        ;;
        # Oops...
        *)
          [[ "$REPO_ARG" == */ ]] && REPO_ARG="echo ${REPO_ARG%?}"
          [[ -d "$REPO_ARG" || $(repo manifest | grep "$REPO_ARG") ]] && REPO_ARG="auto" && PATH_ARG="$1"
          [[ -d "$PATH_ARG" ]] || echo "Unknown argument \"$REPO_ARG\" for reposync, Defaulting to workspace." ;;
    esac

    if [[ "$3" == "quiet" ]]; then
    QUIET_ARG="-q"
    fi
    # Sync!! Use the power of shell scripting!
    echo "Using $THREADS_REPO threads for sync."
    repo sync $QUIET_ARG --jobs-network=4 --jobs-checkout=$THREADS_REPO \
        --fail-fast --force-sync -c --no-clone-bundle --no-tags --optimized-fetch \
        --retry-fetches=10 --prune --no-repo-verify $2 $PATH_ARG
    return $?
}

# This is repoREsync. It REsyncs. Self-explanatory?
function reporesync() {
    echo "Preparing..."
    FRSTDIR="$(pwd)"
    # Let's cd to the top of the working tree
    # Hoping that we don't land in the home directory.
    cd $(gettop)
    # Critical security check to prevent deleting home directory if the build
    # directory has been removed from the work tree for whatever reason.
    if [[ "$(pwd)" == "$(ls -d ~)" ]]; then
        # Let's warn the user about this bad state.
        echoe "WARNING: 'gettop' is returning your \033[1;91mhome directory\033[0m!"
        echoe "         In order to protect your data, this process will be aborted now."
        return 1
    else
        # Oh yeah, we passed!
        echob "Security check passed. Continuing."
    fi

    # Now let's handle the first argument as always
    case "$1" in

        # Do a full sync
        #   full:       just delete the working tree directories and sync normally
        #   full-x:     delete everything except manifest and repo tool, means
        #               you need to resync everything again.
        #   full-local: don't update the repositories, only do a full resync locally
        full)
            # Print a very important message
            echoe \
                "WARNING: This process will delete \033[1myour whole source tree!\033[0m"
            # Ask if the girl or guy really wants to continue.
            if [ "$2" != "confident" ]; then
            # Check if shell is ZSH by checking ZSH_NAME var, which is only set for zsh.
            if [[ ! -z "$ZSH_NAME" ]]; then # In use shell is zsh
                read -k 1 -r "?Do you want to continue? [y\N] : "
            else
                # Shell isn't zsh, so assume bash syntax.
                read -p "Do you want to continue? [y\N] : " \
                     -n 1 -r
            fi
            # Check the reply.
            [[ ! $REPLY =~ ^[Yy]$ ]] && echoe "\nAborted." && return 1
            fi
            # Print some lines of words
            echoe "\n"
            echob "Full source tree resync will start now."
            # Just in case...
            echo  "Your current directory is: $(pwd)"
            # ... read the printed lines so you know what's going on.
            echon "If you think that the current directory is wrong, you will "
            echo  "now have time to safely abort this process using CTRL+C."
            echoen "\n"
            echon  "Waiting for interruption..."
            # Wait 4 lovely seconds which can save your life
            sleep 4
            # Wipe out the above line, now it is redundant
            echoen "\r\033[K\r"
            echoen "Got no interruption, continuing now!"
            echoen "\n"
            # Collect all directories found in the top of the working tree
            # like build, abi, art, bionic, cts, dalvik, external, device, ...
            # and then remove them, and show the user the beautiful progress
            echo "Collecting and removing directories..."
            echo -en "\n\r"
            for ff in *; do
                case "$ff" in
                  "." | ".." | ".repo");;
                  *)
                      echo -en "\rRemoving $ff\033[K"
                      rm -rf "$ff"
                  ;;
                esac
            done
            echo -en "\n"
            # And let's sync!
            echo "Starting sync..."
            reposync
        ;;

        repo)
            echob "Resyncing $1..."
            rm -rf $1
            reposync single $1
        ;;

        # Help me!
        "")
            tuuru_help_reporesync
            cd $FRSTDIR
            return 0
        ;;

    esac
    cd $FRSTDIR
}

function strtrim() {
  sed -e 's/^ *//g' -e 's/ *$//g'
}

function strsplit() {
  cut -d "$1" -f$2
}

function splitix_and_trim() {
  local ix=$1
  local split="$2"
  shift 2
  echo "$@" | strsplit "$split" $ix | strtrim
}

# Resets all repositories to their corresponding remote state
# as defined in the manifest
function reporeset() {
  if [ -z "$BASH_VERSION" ]; then
    bash -ic "cd $(gettop) && source build/envsetup.sh && reporeset"
    return $?
  fi
  echo 'Resetting source tree back to remote state.' \
       'Any unsaved work will be gone.'
  cd .repo/manifests && git reset --hard m/kasumi-v1

  local TOP="$(gettop)"

  repomanifest=$(repo manifest)
  function repomanifest() {
    cat <<EOF
$repomanifest
EOF
  }

  while read line; do
    local repodir=$(splitix_and_trim 1 ':' "$line")
    if [ ! -d "$(gettop)/$repodir" ]; then
      continue
    fi
    local reponame=$(splitix_and_trim 2 ':' "$line")
    local usekey="path"
    local usevalue="$repodir"
    if [ "$(repomanifest | xmlstarlet sel -t -v "//project[@path='$repodir']/@path")" != \
          "$repodir" ]; then
      local usekey="name"
      local usevalue="$reponame"
    fi
    local path="$repodir"
	repo_remote=$(repomanifest | xmlstarlet sel -t -v "/manifest/project[@path='$path']/@remote" || \
                  repomanifest | xmlstarlet sel -t -v "/manifest/default/@remote")
	repo_revision=$(repomanifest | xmlstarlet sel -t -v "/manifest/project[@path='$path']/@revision" || \
                    repomanifest | xmlstarlet sel -t -v "/manifest/default[@remote='$repo_remote']/@revision" || :)
	if [ -z "$repo_revision" ]
	then
		repo_revision=$(repomanifest | xmlstarlet sel -t -v "/manifest/remote[@name='$repo_remote']/@revision" || :)
	fi
	short_revision=${repo_revision/refs\/heads\//}
    short_revision=${repo_revision/refs\/tags\//}
	repo_url=$(repomanifest | xmlstarlet sel -t -v "/manifest/remote[@name='$repo_remote']/@fetch" || \
               repomanifest | xmlstarlet sel -t -v "/manifest/default[@remote='$repo_remote']/@fetch")
	if [ -z "$repo_revision" ]
	then
		if [ -z "$ROM_REVISION" ]
		then
			echo -e "\033[1mWarning: unable to determine revision and ROM_REVISION or ROM_VERSION not set! \033[0m"
			repo_revision="kasumi-v1"
		else
			echo -e "Note: unable to determine revision, defaulting to $ROM_REVISION"
			repo_revision="$ROM_REVISION"
		fi
	fi
	local remote="$repo_remote"
	local revision="$repo_revision"
	local remote="$remote/"
    repo_url="$repo_url$reponame"
    pushd $TOP/$repodir
	echo "$repodir: resetting and cleaning up untracked files/folders"
	git rebase --abort 2> /dev/null > /dev/null || git merge --abort 2> /dev/null > /dev/null || git revert --abort 2> /dev/null > /dev/null || git cherry-pick --abort 2> /dev/null > /dev/null || :
    git stash >/dev/null 2>/dev/null || : # :D
    git reset --hard kasumi/$(echo $revision | sed -re 's/^refs\/heads\/(.*)$/\1/') 2>/dev/null || git reset --hard $remote$revision 2> /dev/null || ( [ "$repo_name" != "aosp" ] && git reset --hard kasumi/$revision ) 2> /dev/null || git reset --hard $revision 2> /dev/null || git reset --hard
    git clean -fdx || :
    popd
    echo
  done < <(repo list)

  unset repomanifest
}

# Completely cleans everything and deletes all untracked files
# Deprecated.
function reposterilize() {
  echo -e '\033[1mNote: This function is deprecated.' \
           'It might end up getting removed in the future.' \
           '\nUse reporeset instead.\033[0m'
  if [[ "$(pwd)" == "$(realpath ~)" ]]; then
    echo "Aborted because you are in your home dir"
    return 1
  elif [[ "$(gettop)" == "" ]]; then
    echo "Aborted, top is not set"
    return 1
  fi
  echo "Warning: Any unsaved work will be gone! Press CTRL+C to abort."
  for i in {5..0}; do
    echo -en "\r\033[K\rStarting sterilization in $i seconds"
    sleep 1
  done
  local startdir="$(gettop)"
  echo
  set +e
  while read dir; do
    cd $startdir
    if [[ "$dir" == *"${startdir}/.repo/"* ]]; then continue; fi
    cd "$dir/../"
    nogitdir="$(realpath $dir/..)"
    reladir="${nogitdir/$startdir\//}"
    echo " - $reladir"
    if [[ "$reladir" == "hardware/"* ]]; then
      echo "  This is a hardware repository. Only resetting."
      git reset
      git reset --hard
      git clean -fd
      continue
    fi
    if [[ "$reladir" == "prebuilts/"* ]]; then
      echo "  This is a prebuilts repository. Only resetting."
      git reset
      git reset --hard
      git clean -fd
      continue
    fi
    git revert --abort 2>/dev/null
    git rebase --abort 2>/dev/null
    git cherry-pick --abort 2>/dev/null
    git reset 2>/dev/null
    git reset --hard kasumi/kasumi-v1 2>/dev/null \
 || git reset --hard github/lineage-18.1 2>/dev/null \
 || git reset --hard materium/materium-v1 2>/dev/null \
 || git reset --hard devices/kasumi-v1 2>/dev/null \
 || git reset --hard 2>/dev/null
    git clean -fd
  done < <(find "$startdir/" -name ".git" -type d)
  cd "$startdir"
  unset startdir
  set -e
  return 0
}

function resetmanifest() {
  cd $(gettop)/.repo/manifests
  git fetch origin kasumi-v1 2>&1 >/dev/null
  git reset --hard origin/kasumi-v1 2>&1 >/dev/null
  cd $(gettop)
}

function addghforwd() {
  local testremote=$(git remote -v | grep "git.polycule.co")
  if [ -z "$testremote" ]; then
    echo "This tree doesn't have Git-Polycule remote assigned. Abort!"
    return 1
  else
    echo "Adding GitHub remote..."
    export polyremote=$(git remote get-url $(git remote -v | grep "git.polycule.co" | grep fetch | sed 's/	.*//g'))
    export reponame=$(echo "$polyremote" | sed 's/.*\//android_/g')
    git remote add gh https://github.com/ProjectKasumi/"$reponame"
    echo "Pushing to GitHub..."
    git push -f gh HEAD:kasumi-v1 || export addghfallback=true && adddevsforwd
    echo "All done!"
  fi
}

function adddevsforwd() {
  if [ ! "$addghfallback" ]; then
    echo "This function is meant as a fallback for addghforwd as of now."
    echo "If you can turn this into a full fledged standalone function, do so and send patch to windowz414@projectkasumi.xyz."
    return 1
  else
    echo "GitHub remote failed, Kasumi-Devices to rescue!"
    git remote set-url gh https://github.com/Kasumi-Devices/"$reponame"
    echo "Pushing again..."
    git push -f gh HEAD:kasumi-v1 || echo "All attempts have failed. Abort!"
    return 1
  fi
}

mirrorAll() {
  TOP="$(gettop)" bash -i "$(gettop)/external/tuuru/kasumi-no-tuuru/scripts/mirror_all.sh" $@
}

function print_product_packages() {
    get_build_var PRODUCT_PACKAGES
}

function pretty_print_product_packages() {
    print_product_packages | tr " " "\n" | sort -u
}

source $(gettop)/external/tuuru/kasumi-no-tuuru/mergetools.sh

return 0
