#!/usr/bin/env python

import os
import sys
import argparse
import subprocess
from i3ipc import Connection

def check_direction(direction: str) -> bool:
    # check if Sway/i3 IPC is available
    try:
        i3 = Connection()
    except Exception as e:
        print(f"Error connecting to Sway IPC: {e}", file=sys.stderr)
        return False

    tree = i3.get_tree()
    focused = tree.find_focused()

    # check if a window is actually focused
    if not focused:
        return False

    # we start at the focused window and climb up the family tree
    current = focused

    while current.parent:
        parent = current.parent
        # we only care if the parent manages vertical splits
        # (and isn't a tabbed/stacked container, unless you want to count those)
        if parent.layout == 'splitv':
            # prevent ValueError if "current" is missing from nodes
            if current in parent.nodes:
                index = parent.nodes.index(current)
                #------------------
                # check UP: if window is not the first child, there is another window above
                if direction == "up" and index > 0:
                    return True
                #------------------
                # check DOWN: if window is NOT the last child, there is another window below
                elif direction == "down" and index < len(parent.nodes) - 1:
                    return True
                #------------------
        # if we didn't find a neighbor here, we climb to the grandparent
        current = parent
    # if we reached the root (workspace) without finding a neighbor
    return False


def main():
    # use argparse to strictly validate input: ["up", "down", "right", "left"]
    parser = argparse.ArgumentParser(description="Check if a window exists above or below the focused window in Sway.")
    parser.add_argument("direction", choices=["up", "down", "right", "left"], help="Direction to check.")
    args = parser.parse_args()

    # window navigation dispatcher: lan-mouse toggle / normal window navigation
    if (args.direction == "down"):
        # check for window below
        if (check_direction(args.direction)):
            # there is another window below --> normal navigation
            subprocess.run(["swaymsg", "focus", args.direction])
        else:
            # there isn't another window below --> lan-mouse toggle
            script_path = os.path.expandvars("$XDG_CONFIG_HOME/scripts/lanmouse-switch.sh")
            if "$XDG_CONFIG_HOME" in script_path:
                script_path = os.path.expanduser("~/.config/scripts/lanmouse-switch.sh")
            subprocess.run(["swaymsg", "exec", f"{script_path} toggle"])

    # normal window navigation
    elif (args.direction in ["up", "left", "right"]):
        subprocess.run(["swaymsg", "focus", args.direction])

    # invalid "direction" parameter
    else:
        sys.exit(1)

if __name__ == "__main__":
    main()
