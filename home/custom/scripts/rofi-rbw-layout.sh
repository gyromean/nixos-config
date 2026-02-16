#!/usr/bin/env bash

# store main keyboard name
KEYBOARD_NAME="$(hyprctl -j devices | jq -r '.keyboards[] | select(.main == true) | .name')"

rofi-rbw

# invoke layout update (NOOP) for the main keyboard, so that hyprland goes back to the active layout
hyprctl --batch "switchxkblayout $KEYBOARD_NAME prev ; switchxkblayout $KEYBOARD_NAME next"
