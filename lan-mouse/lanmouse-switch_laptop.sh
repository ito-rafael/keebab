#!/usr/bin/env bash

# Usage:
# ./lanmouse-switch.sh toggle
# ./lanmouse-switch.sh left
# ./lanmouse-switch.sh right
# ./lanmouse-switch.sh last

# alternative to ydotool: wlrctl
# eg: "wlrctl pointer move -9999 -9999"
#
# !!! I don't know why, but when using "ydotool mousemove", the coordinates required are dividing by 2 !!!

OUTPUT_CENTRAL="HDMI-A-1" # primary
OUTPUT_LEFT="DP-1"        # secondary
OUTPUT_RIGHT="DVI-I-1"    # tertiary

COMMAND="$1"
case "$COMMAND" in

"toggle")
    # [local]
    ydotool mousemove -x 9999 -y 9999  # bottom right
    ydotool mousemove -x -480 -y -9999 # top middle
    # [remote]
    #ssh catuaba "ydotool mousemove -x -9999 -y -9999 && ydotool mousemove -x 1440 -y 270"
    ssh catuaba "export SWAYSOCK=\$(ls /run/user/$(id -u)/sway-ipc.*.sock | head -n 1); swaymsg focus output $OUTPUT_CENTRAL" >/dev/null
    ;;

"right")
    # [local]
    ydotool mousemove -x 9999 -y 9999  # bottom right
    ydotool mousemove -x -480 -y -9999 # top middle
    # [remote]
    #ssh catuaba "ydotool mousemove -x -9999 -y -9999 && ydotool mousemove -x 2190 -y 480"
    ssh catuaba "export SWAYSOCK=\$(ls /run/user/$(id -u)/sway-ipc.*.sock | head -n 1); swaymsg focus output $OUTPUT_RIGHT" >/dev/null
    ;;

"left")
    # [local]
    ydotool mousemove -x 9999 -y 9999  # bottom right
    ydotool mousemove -x -480 -y -9999 # top middle
    # [remote]
    #ssh catuaba "ydotool mousemove -x -9999 -y -9999 && ydotool mousemove -x 480 -y 270"
    ssh catuaba "export SWAYSOCK=\$(ls /run/user/$(id -u)/sway-ipc.*.sock | head -n 1); swaymsg focus output $OUTPUT_LEFT" >/dev/null
    ;;

esac
