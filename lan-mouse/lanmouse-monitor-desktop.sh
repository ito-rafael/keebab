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
UNIT="lan-mouse"
# define message to monitor on the output of journalctl
TRIGGER_LEAVING="client 0 acknowledged the connection!"
TRIGGER_RETURNING="releasing capture: left remote client device region"
# set cooldown (in seconds) to avoid double trigger
COOLDOWN=1
LAST_TRIGGER=0

# monitor the journal for the specific user unit
journalctl --user -u $UNIT -f -n 0 | while read -r line; do
    CURRENT_TIME=$(date +%s)

    # switching to client
    if [[ "$line" == *"$TRIGGER_LEAVING"* ]]; then
        # check if enough time (cooldown) has passed since the last trigger
        if ((CURRENT_TIME - LAST_TRIGGER >= COOLDOWN)); then
            echo -n "[$(date '+%Y-%m-%d %H:%M:%S')] Switching mouse/keyboard to the client. Disabling xremap..."
            # FN_F1: xremap keybinding for switching between default/lan-mouse modes
            ydotool key 466:1 466:0 # FN_F1
            # append "Done!" or "Failed!" to the previous line according to the script status
            [ $? -eq 0 ] && echo " Done!" || echo " Failed!"
            LAST_TRIGGER=$CURRENT_TIME
        fi

    # returning to server
    elif [[ "$line" =~ $TRIGGER_RETURNING ]]; then
        # check if enough time (cooldown) has passed since the last trigger
        if ((CURRENT_TIME - LAST_TRIGGER >= COOLDOWN)); then
            echo -n "[$(date '+%Y-%m-%d %H:%M:%S')] Mouse/keyboard returned to server. Enabling xremap back..."
            # FN_F1: xremap keybinding for switching between default/lan-mouse modes
            ydotool key 466:1 466:0 # FN_F1
            # append "Done!" or "Failed!" to the previous line according to the script status
            [ $? -eq 0 ] && echo " Done!" || echo " Failed!"
            LAST_TRIGGER=$CURRENT_TIME
        fi

    fi
done
