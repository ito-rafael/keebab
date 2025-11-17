#!/usr/bin/env bash
#
# This script is used to control the Caps Lock LED.
#
#=================================================
# help menu and usage message
#=================================================
usage="$(basename "$0") destination action [-h]

where:
    -h, --help      show this help text
    action          action to be performed, can be one of the following options:
      \"status\"      returns the status of the Caps Lock LED
      \"on\"          set Caps Lock LED on
      \"off\"         set Caps Lock LED off
      \"toggle\"      toggles the Caps Lock LED
"
#=================================================
# print help menu
if [[ $1 == '-h' || $1 == '--help' || $1 == '' ]]; then
    printf "Script to control the Caps Lock LED.\n\n"
    echo "$usage"
    exit
fi

#=================================================
# parse parameters
ACTION=$1
CAPSLOCK_FILE='/tmp/capslock_status.tmp'
PATH_PREFIX="/sys/class/leds"

# get capslock input
CAPSLOCK_INPUT=$(ls $PATH_PREFIX | grep capslock | sort -V | head -n1)

# read Caps Lock brightness LED
BRIGHTNESS_FILE=$PATH_PREFIX"/"$CAPSLOCK_INPUT"/brightness"
BRIGHTNESS=$(cat $BRIGHTNESS_FILE)

#=================================================
# perform action requested
case "${ACTION}" in
    "status")
        exit 0
        ;;
    "on")
        exit 0
        ;;
    "off")
        exit 0
        ;;
    "toggle")
        exit 0
        ;;
    *)
        exit 1
        ;;
esac
