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
                 "left")  wtype -M ctrl -k c -m ctrl -k n ;;
                 "down")  wtype -M ctrl -k c -m ctrl -k e ;;
                 "up")    wtype -M ctrl -k c -m ctrl -k i ;;
                 "right") wtype -M ctrl -k c -m ctrl -k o ;;
            esac
            ;;
        *) swaymsg focus "$DIRECTION" ;;
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
    [Ee]macs*) emacsclient -s efs --suppress-output --eval "(zoom-window-zoom)" ;;
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
