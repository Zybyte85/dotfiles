#!/usr/bin/env bash

# Configuration
DIR="$HOME/Pictures/Screenshots"
NAME="screenshot_$(date +%Y-%m-%d_%H-%M-%S).png"
FILE="$DIR/$NAME"
SOUND="/usr/share/sounds/freedesktop/stereo/camera-shutter.oga"

# Ensure directory exists
mkdir -p "$DIR"

# Do region, window, or full screen
if [ "$1" = "region" ]; then
  grim -g "$(slurp -w 0)" "$FILE"
elif [ "$1" = "window" ]; then
  pos_x=$(hyprctl -j activewindow | jq -r ".at[0]")
  pos_y=$(hyprctl -j activewindow | jq -r ".at[1]")
  size_x=$(hyprctl -j activewindow | jq -r ".size[0]")
  size_y=$(hyprctl -j activewindow | jq -r ".size[1]")

  grim -g "$pos_x,$pos_y ${size_x}x${size_y}" "$FILE"
else
  grim "$FILE"
fi

# Exit if grim was cancelled (e.g., hitting ESC during slurp)
[ ! -f "$FILE" ] && exit 0

# Play shutter sound in the background
pw-play "$SOUND" &

# Copy to clipboard
wl-copy <"$FILE"

echo "$FILE"

ACTION=$(notify-send "Screenshot Captured" \
  -i "$FILE" \
  -a "Grim" \
  --action="open=Open" \
  --action="delete=Delete")

# Handle the action
case "$ACTION" in
"open")
  xdg-open "$FILE"
  ;;
"delete")
  rm "$FILE"
  ;;
esac
