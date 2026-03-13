#!/usr/bin/env bash

shopt -s extglob  # enable special variable syntax

TERMINAL_LIST=(
    "kitty"
    "dropdown_terminal"
    "dropdown_python"
)
BROWSER_LIST=(
    "brave*"
    "firefox*"
    "chromium"
)
CHROMIUM_BROWSER_LIST=(
    "brave*"
    "chromium"
)
SCRATCHPAD_LIST=(
    "dropdown_terminal"
    "dropdown_python"
    "scrcpy"
    "Brave-browser-beta"
    "Keymapp"
    "keymapp"
)
EMACS_SSH_LIST=(
    "*: emacsclient --create-frame* --alternate-editor=*emacs*"
    "*: emacsclient -c* -a *emacs*"
    "*: ecd"
    "*: ec"
)
CEDILLA_LIST=(
    "brave*"
    "chromium"
)

IFS='|'  # set separator to pipe temporarily
TERMINALS="@(${TERMINAL_LIST[*]})"
BROWSERS="@(${BROWSER_LIST[*]})"
CHROMIUM_BROWSER="@(${CHROMIUM_BROWSER_LIST[*]})"
SCRATCHPADS="@(${SCRATCHPAD_LIST[*]})"
EMACS_SSHS="@(${EMACS_SSH_LIST[*]})"
CEDILLAS="@(${CEDILLA_LIST[*]})"
unset IFS  # reset separator

# Usage:
# ./smart_dispatch.sh focus left
# ./smart_dispatch.sh type symbol
# ./smart_dispatch.sh launch

COMMAND="$1"
PARAM="$2"

LANMOUSE_FILE="/tmp/lanmouse-status.tmp"

# get the app_id of the focused window
# some XWayland apps might have null app_id, so we fallback to window_properties.class if needed
FOCUSED_APP=$(swaymsg -t get_tree | jq -r '.. | select(.focused? == true) | if .app_id then .app_id else .window_properties.class end')

case "$COMMAND" in

"focus")
    DIRECTION="$PARAM"
    case "$FOCUSED_APP" in
        #[Ee]macs*) emacsclient -s efs --suppress-output --eval "(evil-window-$DIRECTION 1)" ;;
        #[Ee]macs*) emacsclient -s efs --suppress-output --eval "(efs/external-window-move '$DIRECTION)" ;;
        [Ee]macs*)
            case "$DIRECTION" in
                 "left")  wtype -M ctrl -k c -m ctrl -k n ;;  # (C-c n) evil-window-left
                 "down")  wtype -M ctrl -k c -m ctrl -k e ;;  # (C-c e) evil-window-down
                 "up")    wtype -M ctrl -k c -m ctrl -k i ;;  # (C-c i) evil-window-up
                 "right") wtype -M ctrl -k c -m ctrl -k o ;;  # (C-c o) evil-window-right
            esac
            ;;
        *)
            LANMOUSE_STATUS=$(cat $LANMOUSE_FILE)
            # if lan-mouse is connected, use special script for window navigation
            if [[ "$LANMOUSE_STATUS" == "connected" ]]; then
                swaymsg exec $XDG_CONFIG_HOME/scripts/sway-window-nav.py "$DIRECTION"
            # if lan-mouse is not connected, use standard sway navigation
            else
                swaymsg focus "$DIRECTION"
            fi
            ;;
    esac
    ;;

"focus_output")
    DIRECTION="$PARAM"
    # check if there is only one screen (lan-mouse client)
    if [[ $(swaymsg -t get_outputs | jq length) -eq 1 ]]; then
        swaymsg exec $XDG_CONFIG_HOME/scripts/lanmouse-switch.sh $DIRECTION
    # proceed with normal output focus switch
    else
        swaymsg focus output $DIRECTION
    fi
    ;;

"move")
    DIRECTION="$PARAM"
    case "$FOCUSED_APP" in
        [Ee]macs*)
            case "$DIRECTION" in
                 #"left")  wtype -M ctrl -k w -m ctrl -M shift -k n -m shift ;;  # (C-w N) evil-window-move-far-left
                 #"down")  wtype -M ctrl -k w -m ctrl -M shift -k e -m shift ;;  # (C-w E) evil-window-move-very-bottom
                 #"up")    wtype -M ctrl -k w -m ctrl -M shift -k i -m shift ;;  # (C-w I) evil-window-move-very-top
                 #"right") wtype -M ctrl -k w -m ctrl -M shift -k o -m shift ;;  # (C-w O) evil-window-move-far-right
                 "left")  emacsclient -s efs --suppress-output --eval "(evil-window-move-far-left)"    ;;  # C-w N
                 "down")  emacsclient -s efs --suppress-output --eval "(evil-window-move-very-bottom)" ;;  # C-w E
                 "up")    emacsclient -s efs --suppress-output --eval "(evil-window-move-very-top)"    ;;  # C-w I
                 "right") emacsclient -s efs --suppress-output --eval "(evil-window-move-far-right)"   ;;  # C-w O
            esac
            ;;
        *) swaymsg move "$DIRECTION" ;;
    esac
    ;;

"kill")
    case "$FOCUSED_APP" in
        [Ee]macs*) emacsclient -s efs --suppress-output --eval "(evil-quit)" ;;
        *) "$HOME/.config/scripts/hide-or-kill.sh" ;;
    esac
    ;;

"cut")
    case "$FOCUSED_APP" in
        #[Ee]macs*) emacsclient -s efs --suppress-output --eval "(execute-extended-command 1)" ;;
        [Ee]macs*) ;;
        $TERMINALS) ydotool key 29:1 42:1 45:1 45:0 42:0 29:0 ;; # C-S-x
        *) ydotool key 29:1 45:1 45:0 29:0 ;; # C-x
    esac
    ;;

"copy")
    case "$FOCUSED_APP" in
        #[Ee]macs*) emacsclient -s efs --suppress-output --eval "(evil-yank)" ;;
        [Ee]macs*) wtype -M shift -k f17 ;; # S-f17
        $TERMINALS) ydotool key 29:1 42:1 46:1 46:0 42:0 29:0 ;; # C-S-c
        libreoffice-calc) ydotool key 29:1 42:1 46:1 46:0 42:0 29:0 ;; # C-S-c
        *) ydotool key 29:1 46:1 46:0 29:0 ;; # C-c
    esac
    ;;

"paste")
    case "$FOCUSED_APP" in
        #[Ee]macs*) emacsclient -s efs --suppress-output --eval "(evil-paste-after 1)" ;;
        [Ee]macs*) wtype -M ctrl -k f17 ;; # C-f17
        $TERMINALS) ydotool key 29:1 42:1 47:1 47:0 42:0 29:0 ;; # C-S-v
        *) ydotool key 29:1 47:1 47:0 29:0 ;; # C-v
    esac
    ;;

"fullscreen")
    case "$FOCUSED_APP" in
        [Ee]macs*) emacsclient -s efs --suppress-output --eval "(with-current-buffer (window-buffer (selected-window)) (zoom-window-zoom))" ;;
        *) swaymsg fullscreen toggle ;;
    esac
    ;;

"new_terminal")
    case "$FOCUSED_APP" in
        [Ee]macs*) emacsclient -n -s efs --suppress-output --eval "(progn (split-window-autotiling) (other-window 1) (counsel-find-file))" ;;
        *) kitty ;;
    esac
    ;;

"type")
    CHAR="$PARAM"
    case "$FOCUSED_APP" in
        $CHROMIUM_BROWSER) wl-copy "$CHAR" && wtype -M ctrl v -m ctrl ;;
        *) wtype $CHAR ;;
    esac
    ;;

esac
