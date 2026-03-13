#!/usr/bin/env bash

# description:
#   script for desktops to disable/enable xremap keybindings for lan-mouse (software KVM).
# how it works:
#   it monitors the output of the journal for the lan-mouse unit, and once it
#   detects that the cursor leaved/returned to/from the client (laptop), it runs
#   a ydotool command to disable/enable xremap keybindings. This allows
#   keybindings bypasses for the cliend when the mouse/keyboard is there.

# Usage:
#   This is script is meant to be used as a daemon. A systemd user service
#   is responsible for launching and controlling it.

# define systemd unit to monitor
UNIT="lanmouse"
STATUS_FILE="/tmp/lanmouse-status.tmp"

# define messages to monitor on the output of journalctl
TRIGGER_CONNECTION='lan_mouse::connect] client (0) connected @ '
TRIGGER_DISCONNECTION_START='lan_mouse::connect] '
TRIGGER_DISCONNECTION_END=' send error `conn is closed`, closing connection'
TRIGGER_LEAVING='client 0 acknowledged the connection!'
TRIGGER_RETURNING='releasing capture: left remote client device region'

# set cooldown (in miliseconds) to avoid double trigger
COOLDOWN=250
LAST_TRIGGER=0

# monitor the journal for the specific user unit
journalctl --user -u $UNIT -f -n 0 | while read -r line; do
    CURRENT_TIME=$(($(date +%s%N) / 1000000))
    case "$line" in

    *"$TRIGGER_CONNECTION"*)
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Connection stablished. Updating lanmouse-status file."
        echo "connected" >$STATUS_FILE
        ;;

    *"$TRIGGER_DISCONNECTION_START"*"$TRIGGER_DISCONNECTION_END"*)
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Connection stablished. Updating lanmouse-status file."
        echo "disconnected" >$STATUS_FILE
        ;;

    # switching to client
    *"$TRIGGER_LEAVING"*)
        # check if enough time (cooldown) has passed since the last trigger
        if ((CURRENT_TIME - LAST_TRIGGER >= COOLDOWN)); then
            echo -n "[$(date '+%Y-%m-%d %H:%M:%S')] Switching mouse/keyboard to the client. Disabling xremap..."
            # FN_F1: xremap keybinding for switching mode: default --> lan-mouse
            ydotool key 466:1 466:0 # FN_F1
            # append "Done!" or "Failed!" to the previous line according to the script status
            [ $? -eq 0 ] && echo " Done!" || echo " Failed!"
            LAST_TRIGGER=$CURRENT_TIME

            # update status file
            echo "active" >$STATUS_FILE
        fi
        ;;

    # returning to server
    *"$TRIGGER_RETURNING"*)
        # check if enough time (cooldown) has passed since the last trigger
        if ((CURRENT_TIME - LAST_TRIGGER >= COOLDOWN)); then
            echo -n "[$(date '+%Y-%m-%d %H:%M:%S')] Mouse/keyboard returned to server. Enabling xremap back..."
            # FN_F2: xremap keybinding for switching mode: lan-mouse --> default
            ydotool key 467:1 467:0 # FN_F2
            # append "Done!" or "Failed!" to the previous line according to the script status
            [ $? -eq 0 ] && echo " Done!" || echo " Failed!"
            LAST_TRIGGER=$CURRENT_TIME

            # update status file
            echo "connected" >$STATUS_FILE
        fi
        ;;

    esac
done
