#!/usr/bin/env bash

# description:
#   script to share clipboard via lan-mouse (software KVM) with the sender host.
# how it works:
#   it monitors the output of the journal for the lan-mouse unit, and once it
#   detects that the cursor moved back to the sender, it runs push-clipboard.sh
#   script that sends the clipboard back via SSH forced commands (previously
#   configured in ~/.ssh/authorized-keys).

# Usage:
#   This is script is meant to be used as a daemon. A systemd user service
#   is responsible for launching and controlling it.

# define systemd unit to monitor
UNIT="lanmouse"
STATUS_FILE="/tmp/lanmouse-status.tmp"
# define messages to monitor on the output of journalctl
TRIGGER_ENTERING_START="releasing capture: "
TRIGGER_ENTERING_END=" entered this device"
TRIGGER_LEAVING="releasing capture: no active client at this position"
TRIGGER_CONNECTION="lan_mouse::listen] dtls client connected, ip: "
TRIGGER_DISCONNECTION_START="lan_mouse::emulation] releasing keys: "
TRIGGER_DISCONNECTION_END=" not responding!"

# set cooldown (in miliseconds) to avoid double trigger
COOLDOWN=250
LAST_TRIGGER=0

# monitor the journal for the specific user unit
journalctl --user -u "$UNIT" -f -n 0 | cat | while read -r line; do
    CURRENT_TIME=$(($(date +%s%N) / 1000000))
    case "$line" in

    *"$TRIGGER_CONNECTION"*)
        # adjust Sway scale
        $XDG_CONFIG_HOME/scripts/sway-scale.sh 1.25
        echo "connected" >$STATUS_FILE
        ;;

    *"$TRIGGER_DISCONNECTION_START"*"$TRIGGER_DISCONNECTION_END"*)
        # adjust Sway scale
        $XDG_CONFIG_HOME/scripts/sway-scale.sh 1.00
        echo "disconnected" >$STATUS_FILE
        ;;

    # leaving this host --> returning to desktop
    *"$TRIGGER_LEAVING"*)
        # check if enough time (cooldown) has passed since the last trigger
        if ((CURRENT_TIME - LAST_TRIGGER >= COOLDOWN)); then
            echo -n "[$(date '+%Y-%m-%d %H:%M:%S')] Mouse returned to PC. Sending clipboard and re-enabling xremap default mode..."
            # send clipboard via SSH forced command
            $HOME/.config/scripts/push-clipboard.sh catuaba >/dev/null
            # re-enable xremap's default mode (FN_F2)
            ssh catuaba "ydotool key 467:1 467:0"
            # append "Done!" or "Failed!" to the previous line according to the script status
            [ $? -eq 0 ] && echo " Done!" || echo " Failed!"
            LAST_TRIGGER=$CURRENT_TIME

            # update status file
            echo "connected" >$STATUS_FILE
        fi
        ;;

    # entering this host
    *"$TRIGGER_ENTERING_START"*"$TRIGGER_ENTERING_END"*)
        # update status file
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Mouse entered in client. Updating lan-mouse status file."
        echo "active" >$STATUS_FILE
        ;;

    esac
done
