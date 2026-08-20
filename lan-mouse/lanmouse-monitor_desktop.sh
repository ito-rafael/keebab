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

# enable extended globbing
shopt -s extglob

# define systemd unit to monitor
UNIT="lanmouse"
STATUS_FILE="/tmp/lanmouse-status.tmp"

# define messages to monitor on the output of journalctl
TRIGGER_CONNECTION='lan_mouse::connect] client (0) connected @ '
TRIGGER_DISCONNECTION_START='lan_mouse::connect] '
TRIGGER_DISCONNECTION_END_1=' send error `conn is closed`, closing connection'
TRIGGER_DISCONNECTION_END_2=' connection closed'
TRIGGER_LEAVING='entering client'
TRIGGER_RETURNING='releasing capture: left remote client device region'

# state machine: tracks where the mouse currently is to prevent double triggers
# valid states: "disconnected", "server", "client"
MOUSE_STATE="disconnected"

# monitor the journal for the specific user unit
journalctl --user -u "$UNIT" -f -n 0 | while read -r line; do
    case "$line" in

    *"$TRIGGER_CONNECTION"*)
        echo "Connection established. Updating lanmouse-status file to \"connected\"."
        # adjust Sway scale
        ssh ipf "swaymsg exec $XDG_CONFIG_HOME/scripts/sway-scale.sh 1.25"
        echo "connected" >$STATUS_FILE
        MOUSE_STATE="server"
        ;;

    *"$TRIGGER_DISCONNECTION_START"*@("$TRIGGER_DISCONNECTION_END_1"|"$TRIGGER_DISCONNECTION_END_2")*)
        echo "Connection interrupted. Updating lanmouse-status file to \"disconnected\"."
        # adjust Sway scale
        ssh ipf "swaymsg exec $XDG_CONFIG_HOME/scripts/sway-scale.sh 1.00"
        echo "disconnected" >$STATUS_FILE
        MOUSE_STATE="disconnected"
        # FN_F2: xremap keybinding for switching mode: lan-mouse --> default
        ydotool key 467:1 467:0 # FN_F2
        ;;

    # switching to client
    *"$TRIGGER_LEAVING"*)
        # check the state machine to prevent double-triggers
        if [[ "$MOUSE_STATE" != "client" ]]; then
            echo -n "Switching mouse/keyboard to the client. Disabling xremap..."
            # FN_F1: xremap keybinding for switching mode: default --> lan-mouse
            ydotool key 466:1 466:0 # FN_F1
            # append "Done!" or "Failed!" to the previous line according to the script status
            [ $? -eq 0 ] && echo " Done!" || echo " Failed!"

            # update status file
            echo "active" >$STATUS_FILE
            MOUSE_STATE="client"

            # change Waybar color to red (deprecated: command moved to ~/.config/waybar/scripts/xremap-mode.sh)
            #echo '@define-color dynamic_bg rgba(255, 0, 0, 0.5);' > ~/.config/waybar/dynamic-bg.css
        fi
        ;;

    # returning to server
    *"$TRIGGER_RETURNING"*)
        # check the state machine to prevent double-triggers
        if [[ "$MOUSE_STATE" != "server" ]]; then
            echo -n "Mouse/keyboard returned to server. Enabling xremap back..."
            # FN_F2: xremap keybinding for switching mode: lan-mouse --> default
            ydotool key 467:1 467:0 # FN_F2
            # append "Done!" or "Failed!" to the previous line according to the script status
            [ $? -eq 0 ] && echo " Done!" || echo " Failed!"

            # update status file
            echo "connected" >$STATUS_FILE
            MOUSE_STATE="server"

            # reset Waybar color (deprecated: command moved to ~/.config/waybar/scripts/xremap-mode.sh)
            #echo '@define-color dynamic_bg rgba(43, 48, 59, 0.5);' > ~/.config/waybar/dynamic-bg.css
        fi
        ;;

    esac
done
