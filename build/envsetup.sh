function __print_extra_functions_help() {
cat <<EOF
Additional functions:
- mka:             Builds using SCHED_BATCH on all processors.
- pushboot:	   Push a file from your OUT dir to your phone
                   and reboots it, using absolute path.
- repopick:        Utility to fetch changes from Gerrit.
- aospremote:      Add git remote for matching AOSP repository.
- cafremote:       Add git remote for matching CodeAurora repository.
EOF
}

# Make using all available CPUs
function mka() {
    case `uname -s` in
        Darwin)
            make -j `sysctl hw.ncpu|cut -d" " -f2` "$@"
            ;;
        *)
            schedtool -B -n 1 -e ionice -n 1 make -j `cat /proc/cpuinfo | grep "^processor" | wc -l` "$@"
            ;;
    esac
}

function pushboot() {
    if [ ! -f $OUT/$* ]; then
        echo "File not found: $OUT/$*"
        return 1
    fi

    adb root
    sleep 1
    adb wait-for-device
    adb remount

    adb push $OUT/$* /$*
    adb reboot
}

function repopick() {
    set_stuff_for_environment
    T=$(gettop)
    $T/vendor/extras/build/tools/repopick.py $@
}

function aospremote() {
    git remote rm aosp 2> /dev/null
    if [ ! -d .git ]
    then
        echo .git directory not found. Please run this from the root directory of the Android repository you wish to set up.
    fi
    if [ ! "$ANDROID_BUILD_TOP" ]; then
        export ANDROID_BUILD_TOP=$(gettop)
    fi
    PROJECT=$(pwd -P | sed -e "s#$ANDROID_BUILD_TOP\/##; s#-caf.*##; s#\/default##")
    if (echo $PROJECT | grep -qv "^device")
    then
        PFX="platform/"
    fi
    git remote add aosp https://android.googlesource.com/$PFX$PROJECT
    echo "Remote 'aosp' created"
}
export -f aospremote

function cafremote()
{
    git remote rm caf 2> /dev/null
    if [ ! -d .git ]
    then
        echo .git directory not found. Please run this from the root directory of the Android repository you wish to set up.
    fi
    if [ ! "$ANDROID_BUILD_TOP" ]; then
        export ANDROID_BUILD_TOP=$(gettop)
    fi
    PROJECT=$(pwd -P | sed -e "s#$ANDROID_BUILD_TOP\/##; s#-caf.*##; s#\/default##")
    if (echo $PROJECT | grep -qv "^device")
    then
        PFX="platform/"
    fi
    git remote add caf https://source.codeaurora.org/quic/la/$PFX$PROJECT
    echo "Remote 'caf' created"
}
export -f cafremote
