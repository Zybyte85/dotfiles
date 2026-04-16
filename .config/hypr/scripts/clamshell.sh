#!/usr/bin/env bash

# Internal display name
INTERNAL="eDP-1"

# Find the lid directory
LID_STATE="/proc/acpi/button/lid/$(ls /proc/acpi/button/lid/ | head -n 1)/state"

# Count ONLY external monitors (excludes the internal one from the count)
EXTERNAL_COUNT=$(hyprctl monitors -j | jq --arg int "$INTERNAL" 'map(select(.name != $int)) | length')

# Check if lid is closed
LID_CLOSED=false
if grep -q "closed" "$LID_STATE"; then
  LID_CLOSED=true
fi

if [ "$LID_CLOSED" = true ] && [ "$EXTERNAL_COUNT" -ge 1 ]; then
  # CLAMSHELL MODE: Lid closed + at least one external monitor
  hyprctl keyword monitor "$INTERNAL, disable"
else
  # NORMAL MODE: Lid open OR no external monitors
  # Try to grab the rule from nwg-displays config
  CONF_FILE="$HOME/.config/hypr/monitors.conf"

  if [ -f "$CONF_FILE" ]; then
    MONITOR_RULE=$(grep "monitor=$INTERNAL" "$CONF_FILE" | cut -d '=' -f 2-)
  fi

  if [[ -n "$MONITOR_RULE" ]]; then
    hyprctl keyword monitor "$MONITOR_RULE"
  else
    # Fallback to defaults
    hyprctl keyword monitor "$INTERNAL, preferred, auto, 1"
  fi
fi
