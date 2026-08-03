#!/usr/bin/env bash
#
# This script is used to control the Caps Lock LED.
# It relies on XKB remaps that decouples the Caps Lock functionality and the
# Caps Lock LED. The Caps Lock LED is now linked with the Scroll Lock key.
#
# "ydotool key 70:1 70:0" simulates a Scroll Lock key press.
#
#=================================================
# help menu and usage message
#=================================================
usage="$(basename "$0") action [-h]

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
    exit 0
fi

#=================================================
# parse parameters
ACTION=$1
#CAPSLOCK_FILE='/tmp/capslock_status.tmp'
PATH_PREFIX="/sys/class/leds"

# get capslock input
CAPSLOCK_INPUT=$(command ls $PATH_PREFIX | grep capslock | sort -V | head -n1)

# read Caps Lock brightness LED
BRIGHTNESS_FILE="${PATH_PREFIX}/${CAPSLOCK_INPUT}/brightness"

# safety check: ensure the LED file actually exists before proceeding
if [ ! -f "$BRIGHTNESS_FILE" ]; then
    echo "Error: Caps Lock LED brightness file not found."
    exit 1
fi

#=================================================
# helper functions
#=================================================
# get LED status ("0" or "1")
led_status() {
    cat "$BRIGHTNESS_FILE"
}
#---------------------------
# ensure LED is ON
led_on() {
    # if led_status outputs 0, the LED is off, so we toggle it on
    if [ "$(led_status)" -eq 0 ]; then
        ydotool key 70:1 70:0
    fi
}
#---------------------------
# ensure LED is OFF
led_off() {
    # if led_status outputs 1, the LED is on, so we toggle it off
    if [ "$(led_status)" -eq 1 ]; then
        ydotool key 70:1 70:0
    fi
}
#---------------------------
# toggle LED
led_toggle() {
    ydotool key 70:1 70:0
}

#=================================================
# perform action requested
case "${ACTION}" in
    "status")
        led_status
        exit 0
        ;;
    "on"|"1")
        led_on
        exit 0
        ;;
    "off"|"0")
        led_off
        exit 0
        ;;
    "toggle")
        led_toggle
        exit 0
        ;;
    *)
        echo "Error: Unknown action '${ACTION}'"
        echo "$usage"
        exit 1
        ;;
esac
