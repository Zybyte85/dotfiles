#!/usr/bin/env bash

INTERNAL="eDP-1"
CONF_FILE="$HOME/.config/hypr/monitors.conf"
LOCK_FILE="/tmp/hypr-clamshell.lock"

if [ -f "$LOCK_FILE" ]; then
  exit 0
fi
touch "$LOCK_FILE"
trap 'rm -f "$LOCK_FILE"' EXIT

LID_STATE_FILE="/proc/acpi/button/lid/$(ls /proc/acpi/button/lid/ | head -n 1)/state"

LID_CLOSED=false
if grep -q "closed" "$LID_STATE_FILE" 2>/dev/null; then
  LID_CLOSED=true
fi

MONITORS_JSON=$(hyprctl monitors -j 2>/dev/null)
EXTERNAL_COUNT=$(echo "$MONITORS_JSON" | jq --arg int "$INTERNAL" 'map(select(.name != $int)) | length')

CURRENT_STATE="$LID_CLOSED-$EXTERNAL_COUNT"
PREV_STATE_FILE="/tmp/hypr-clamshell-state"

if [ -f "$PREV_STATE_FILE" ] && [ "$(cat "$PREV_STATE_FILE")" = "$CURRENT_STATE" ]; then
  exit 0
fi
echo "$CURRENT_STATE" > "$PREV_STATE_FILE"

sleep 0.5

if [ "$LID_CLOSED" = true ] && [ "$EXTERNAL_COUNT" -ge 1 ]; then
  hyprctl keyword monitor "$INTERNAL, disable"
else
  if [ -f "$CONF_FILE" ]; then
    MONITOR_RULE=$(grep "monitor=$INTERNAL" "$CONF_FILE" | cut -d '=' -f 2-)
  fi

  if [[ -n "$MONITOR_RULE" ]]; then
    hyprctl keyword monitor "$MONITOR_RULE"
  else
    hyprctl keyword monitor "$INTERNAL, preferred, auto, 1"
  fi
fi
