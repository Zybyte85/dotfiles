#!/usr/bin/env bash

# Use the first battery found
BAT_DIR=$(find /sys/class/power_supply -name "BAT*" | head -n 1)
[[ -z "$BAT_DIR" ]] && {
  echo "No battery found"
  exit 1
}

LOW_BAT_PERCENT=20
AC_PROFILE="performance"
BAT_PROFILE="balanced"
LOW_BAT_PROFILE="power-saver"

[[ -n $STARTUP_WAIT ]] && sleep "$STARTUP_WAIT"

prev=""

set_power_profile() {
  # Direct file reads to avoid spawning 'cat'
  read -r status <"$BAT_DIR/status"
  read -r capacity <"$BAT_DIR/capacity"

  if [[ "$status" == "Discharging" ]]; then
    if ((capacity > LOW_BAT_PERCENT)); then
      profile=$BAT_PROFILE
    else
      profile=$LOW_BAT_PROFILE
    fi
  else
    profile=$AC_PROFILE
  fi

  if [[ "$prev" != "$profile" ]]; then
    echo "Setting power profile to: $profile"
    powerprofilesctl set "$profile" || echo "Failed to set profile"
    prev="$profile"
  fi
}

# Initial run
set_power_profile

# Monitor events
upower -m | while read -r _; do
  echo "event happened. running function"
  set_power_profile
done
