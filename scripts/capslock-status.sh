#!/usr/bin/env bash
#
# This script is used to control the status of the Caps Lock.
# It is used by the status bar (Waybar)
#
#=================================================
# help menu and usage message
#=================================================
usage="$(basename "$0") action [-h]

where:
    -h, --help      show this help text
    action          action to be performed, can be one of the following options:
      \"status\"      returns the status of the Caps Lock key
      \"on\"          set Caps Lock on
      \"off\"         set Caps Lock off
      \"toggle\"      toggles the status of Caps Lock
"
#=================================================
# print help menu
if [[ $1 == '-h' || $1 == '--help' || $1 == '' ]]; then
    printf "Script to control the status of the Caps Lock key.\n\n"
    echo "$usage"
    exit
fi

#=================================================
# parse parameters
ACTION=$1
CAPSLOCK_FILE='/tmp/capslock_status.tmp'

# read Caps Lock brightness LED
#PATH_PREFIX="/sys/class/leds"
#CAPSLOCK_INPUT=$(command ls $PATH_PREFIX | grep capslock | sort -V | head -n1)
#BRIGHTNESS_FILE=$PATH_PREFIX"/"$CAPSLOCK_INPUT"/brightness"
#BRIGHTNESS=$(cat $BRIGHTNESS_FILE)

# initialize the state file if it doesn't exist (eg: after a reboot)
if [ ! -f "$CAPSLOCK_FILE" ]; then
    echo 0 > "$CAPSLOCK_FILE"
fi

#=================================================
# helper functions
#=================================================
# get Caps Lock status ("0" or "1")
capslock_status() {
    cat "$CAPSLOCK_FILE"
}
#---------------------------
# ensure Caps Lock is ON
capslock_on() {
    # if capslock_status outputs 0, the Caps Lock is off, so we toggle it on
    if [ "$(capslock_status)" -eq 0 ]; then
        ydotool key 58:1 58:0
        echo 1 > "$CAPSLOCK_FILE"
    fi
}
#---------------------------
# ensure Caps Lock is OFF
capslock_off() {
    # if capslock_status outputs 1, the Caps Lock is on, so we toggle it off
    if [ "$(capslock_status)" -eq 1 ]; then
        ydotool key 58:1 58:0
        echo 0 > "$CAPSLOCK_FILE"
    fi
}
#---------------------------
# toggle Caps Lock
capslock_toggle() {
    ydotool key 58:1 58:0
    if [ "$(capslock_status)" -eq 0 ]; then
        echo 1 > "$CAPSLOCK_FILE"
    else
        echo 0 > "$CAPSLOCK_FILE"
    fi
}

#=================================================
# perform action requested
case "${ACTION}" in
    "status")
        capslock_status
        exit 0
        ;;
    "on"|"1")
        capslock_on
        exit 0
        ;;
    "off"|"0")
        capslock_off
        exit 0
        ;;
    "toggle")
        capslock_toggle
        exit 0
        ;;
    *)
        echo "Error: Unknown action '${ACTION}'"
        echo "$usage"
        exit 1
        ;;
esac
