#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILE_SCRIPT="$SCRIPT_DIR/victus-fan-profile.sh"
HWMON_BASE="/sys/devices/platform/hp-wmi/hwmon"
THERMAL_GLOB="/sys/class/thermal/thermal_zone*/temp"

PIDS=()

usage() {
  cat <<'EOF'
Usage:
  victus-fan-test.sh
  victus-fan-test.sh --seconds 90
  victus-fan-test.sh --workers 8 --seconds 120
  victus-fan-test.sh --seconds 90 --max-temp 92
  victus-fan-test.sh --workers 8 --ramp-step 1 --ramp-interval 6

What it does:
  - Sets HP thermal profile to performance if possible
  - Starts CPU load workers for a fixed time
  - Prints live CPU temperature and fan RPM
  - Stops all workers automatically on exit

Defaults:
  workers = number of CPU cores
  seconds = 90
  max-temp = 92C
  ramp-step = 1 worker
  ramp-interval = 6 seconds
EOF
}

cleanup() {
  local pid
  for pid in "${PIDS[@]:-}"; do
    kill "$pid" 2>/dev/null || true
  done
  wait 2>/dev/null || true
}

trap cleanup EXIT INT TERM

cpu_count() {
  getconf _NPROCESSORS_ONLN 2>/dev/null || echo 4
}

read_temp_c() {
  local temp_file
  for temp_file in $THERMAL_GLOB; do
    if [[ -r "$temp_file" ]]; then
      awk -v t="$(<"$temp_file")" 'BEGIN { printf "%.1f", t / 1000 }'
      return 0
    fi
  done
  echo "n/a"
}

read_temp_mc() {
  local temp_file
  for temp_file in $THERMAL_GLOB; do
    if [[ -r "$temp_file" ]]; then
      cat "$temp_file"
      return 0
    fi
  done
  echo 0
}

fan_files() {
  find "$HWMON_BASE" -maxdepth 2 -type f -name 'fan*_input' 2>/dev/null | sort
}

read_fans() {
  local out=""
  local fan_file
  while IFS= read -r fan_file; do
    out+=$(printf "%s=%sRPM " "$(basename "$fan_file")" "$(<"$fan_file")")
  done < <(fan_files)

  if [[ -z "$out" ]]; then
    echo "fans=n/a"
  else
    printf "%s" "${out% }"
  fi
}

start_workers() {
  local workers="$1"
  local i
  for ((i = 0; i < workers; i++)); do
    bash -lc 'while :; do :; done' &
    PIDS+=("$!")
  done
}

start_one_worker() {
  bash -lc 'while :; do :; done' &
  PIDS+=("$!")
}

maybe_set_performance() {
  if [[ -x "$PROFILE_SCRIPT" ]]; then
    sudo "$PROFILE_SCRIPT" set performance >/dev/null 2>&1 || true
  fi
}

workers="$(cpu_count)"
seconds=90
max_temp=92
ramp_step=1
ramp_interval=6

while [[ $# -gt 0 ]]; do
  case "$1" in
    --workers)
      workers="${2:-}"
      shift 2
      ;;
    --seconds)
      seconds="${2:-}"
      shift 2
      ;;
    --max-temp)
      max_temp="${2:-}"
      shift 2
      ;;
    --ramp-step)
      ramp_step="${2:-}"
      shift 2
      ;;
    --ramp-interval)
      ramp_interval="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if ! [[ "$workers" =~ ^[0-9]+$ ]] || [[ "$workers" -lt 1 ]]; then
  echo "Invalid worker count: $workers" >&2
  exit 1
fi

if ! [[ "$seconds" =~ ^[0-9]+$ ]] || [[ "$seconds" -lt 5 ]]; then
  echo "Invalid duration: $seconds" >&2
  exit 1
fi

if ! [[ "$max_temp" =~ ^[0-9]+$ ]] || [[ "$max_temp" -lt 60 ]] || [[ "$max_temp" -gt 100 ]]; then
  echo "Invalid max temp: $max_temp" >&2
  exit 1
fi

if ! [[ "$ramp_step" =~ ^[0-9]+$ ]] || [[ "$ramp_step" -lt 1 ]]; then
  echo "Invalid ramp step: $ramp_step" >&2
  exit 1
fi

if ! [[ "$ramp_interval" =~ ^[0-9]+$ ]] || [[ "$ramp_interval" -lt 1 ]]; then
  echo "Invalid ramp interval: $ramp_interval" >&2
  exit 1
fi

maybe_set_performance

echo "Starting load test: workers=$workers duration=${seconds}s max_temp=${max_temp}C ramp_step=$ramp_step ramp_interval=${ramp_interval}s"
echo "Press Ctrl+C to stop early."
echo

active_workers=0
next_ramp_at="$SECONDS"

end_time=$((SECONDS + seconds))
while (( SECONDS < end_time )); do
  if (( active_workers < workers && SECONDS >= next_ramp_at )); then
    add_now="$ramp_step"
    if (( active_workers + add_now > workers )); then
      add_now=$((workers - active_workers))
    fi

    for ((i = 0; i < add_now; i++)); do
      start_one_worker
    done

    active_workers=$((active_workers + add_now))
    next_ramp_at=$((SECONDS + ramp_interval))
  fi

  remaining=$((end_time - SECONDS))
  current_temp_mc="$(read_temp_mc)"
  printf "t-%02ds  workers=%d/%d  cpu=%sC  %s\n" "$remaining" "$active_workers" "$workers" "$(awk -v t="$current_temp_mc" 'BEGIN { printf "%.1f", t / 1000 }')" "$(read_fans)"
  if (( current_temp_mc >= max_temp * 1000 )); then
    echo
    echo "Stopping early: CPU reached ${max_temp}C."
    break
  fi
  sleep 2
done

echo
echo "Load test finished."
