#!/usr/bin/env bash

set -euo pipefail

PROFILE_PATH="/sys/firmware/acpi/platform_profile"
CHOICES_PATH="/sys/firmware/acpi/platform_profile_choices"
HWMON_BASE="/sys/devices/platform/hp-wmi/hwmon"

usage() {
  cat <<'EOF'
Usage:
  victus-fan-profile.sh status
  sudo victus-fan-profile.sh set max
  sudo victus-fan-profile.sh set quiet
  sudo victus-fan-profile.sh set cool
  sudo victus-fan-profile.sh set balanced
  sudo victus-fan-profile.sh set performance
  victus-fan-profile.sh watch

Notes:
  - HP Victus on current Fedora kernels usually exposes thermal profiles,
    not direct manual fan PWM control.
  - Lower-noise modes are typically: quiet, then cool.
  - "max" is an alias for the strongest cooling-oriented profile exposed
    by firmware on this machine.
EOF
}

require_file() {
  local path="$1"
  if [[ ! -e "$path" ]]; then
    echo "Missing required path: $path" >&2
    exit 1
  fi
}

fan_files() {
  find "$HWMON_BASE" -maxdepth 2 -type f -name 'fan*_input' 2>/dev/null | sort
}

print_status() {
  require_file "$PROFILE_PATH"
  require_file "$CHOICES_PATH"

  echo "Current profile: $(<"$PROFILE_PATH")"
  echo "Available profiles: $(<"$CHOICES_PATH")"

  local fan_found=0
  while IFS= read -r fan_file; do
    fan_found=1
    printf "%s RPM: %s\n" "$(basename "$fan_file")" "$(<"$fan_file")"
  done < <(fan_files)

  if [[ "$fan_found" -eq 0 ]]; then
    echo "Fan RPM sensors: not exposed"
  fi
}

set_profile() {
  local profile="${1:-}"
  require_file "$PROFILE_PATH"
  require_file "$CHOICES_PATH"

  if [[ -z "$profile" ]]; then
    usage
    exit 1
  fi

  case "$profile" in
    max)
      if grep -qw cool "$CHOICES_PATH"; then
        profile="cool"
      elif grep -qw performance "$CHOICES_PATH"; then
        profile="performance"
      fi
      ;;
  esac

  if ! grep -qw -- "$profile" "$CHOICES_PATH"; then
    echo "Unsupported profile: $profile" >&2
    echo "Available: $(<"$CHOICES_PATH")" >&2
    exit 1
  fi

  if [[ "${EUID}" -ne 0 ]]; then
    echo "Root required to change profile. Run with sudo." >&2
    exit 1
  fi

  printf '%s' "$profile" > "$PROFILE_PATH"
  print_status
}

watch_status() {
  while true; do
    clear
    date
    echo
    print_status
    sleep 2
  done
}

cmd="${1:-status}"

case "$cmd" in
  status)
    print_status
    ;;
  set)
    set_profile "${2:-}"
    ;;
  watch)
    watch_status
    ;;
  -h|--help|help)
    usage
    ;;
  *)
    usage
    exit 1
    ;;
esac
