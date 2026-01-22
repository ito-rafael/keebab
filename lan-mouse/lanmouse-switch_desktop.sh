#!/usr/bin/env bash

# alternative to ydotool: wlrctl
# eg: "wlrctl pointer move -9999 -9999"

#=============================
# [local]
#=============================

# force cursor @ (0,0)
ydotool mousemove -x -9999 -y -9999

# move cursor to bottom middle of the main output (x=1.5*1920; y=1080)
ydotool mousemove -x 2880 -y 1080

#=============================
# [remote]
#=============================

# force cursor @ (1920,1200)
# and then to middle of the screen (x=1920/2; y=1200/2)
# !!! I don't know why, but it's dividing by 4: (x=1920/4; y=1200/4) !!!
ssh ipf "ydotool mousemove -x 9999 -y 9999 && ydotool mousemove -x -480 -y -300"
