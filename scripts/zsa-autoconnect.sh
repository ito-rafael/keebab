#!/usr/bin/env bash

# wait a moment for Keymapp to register the device physically
sleep 2

# use kontroll to connect keyboard to Keymapp
sudo -u rafael /usr/bin/kontroll connect-any
