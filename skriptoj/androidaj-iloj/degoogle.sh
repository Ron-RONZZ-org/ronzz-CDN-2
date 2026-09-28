#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────────────
# degoogle.sh — Uninstall Google apps from one or more Android devices
# Usage: ./degoogle.sh
# ─────────────────────────────────────────────────────────────────────

APP_LIST=(
  "com.google.android.calendar|Google Calendar"
  "com.google.android.contacts|Google Contacts"
  "com.google.android.keep|Google Keep"
  "com.google.android.apps.tachyon|Google Meet"
  "com.google.android.deskclock|Google Clock"
  "com.google.android.dialer|Google Phone"
  "com.google.android.calculator|Google Calculator"
  "com.google.android.apps.youtube.music|YouTube Music"
  "com.google.android.videos|Google TV"
  "com.google.android.apps.maps|Google Maps"
  "com.google.android.as|Google Assistant"
  "com.google.android.marvin.talkback|TalkBack"
  "com.google.android.apps.docs|Google Drive"
  "com.google.android.apps.docs.editors.docs|Google Docs"
  "com.google.android.apps.messaging|Google Messages"
  "com.google.android.apps.photos|Google Photos"
  "com.google.android.youtube|YouTube"
  "com.google.android.projection.gearhead|Android Auto"
  "com.google.android.gm|Gmail"
)

# ─── Colors ──────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

info()  { echo -e "${CYAN}[INFO]${NC}  $*"; }
ok()    { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
err()   { echo -e "${RED}[ERR]${NC}   $*"; }

# ─── Step 1: Verify ADB devices ──────────────────────────────────────
info "Checking for connected ADB devices…"
DEVICES_OUTPUT=$(adb devices 2>/dev/null | tail -n +2 || true)

if [[ -z "$DEVICES_OUTPUT" ]]; then
  err "No ADB devices found. Is adb installed and a device connected?"
  exit 1
fi

# Build arrays of serials that are in "device" state
SERIALS=()
STATES=()
while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  # lines look like: "0123456789ABCDEF	device"
  serial=$(echo "$line" | awk '{print $1}')
  state=$(echo "$line"  | awk '{print $2}')
  SERIALS+=("$serial")
  STATES+=("$state")
done <<< "$DEVICES_OUTPUT"

if [[ ${#SERIALS[@]} -eq 0 ]]; then
  err "No ADB devices found."
  exit 1
fi

echo ""
info "Found ${#SERIALS[@]} ADB device(s):"
echo ""
printf "  %-3s  %-30s  %s\n" "#" "Serial" "State"
printf "  %-3s  %-30s  %s\n" "---" "------------------------------" "------"
for i in "${!SERIALS[@]}"; do
  idx=$((i + 1))
  printf "  ${CYAN}%-3d${NC}  %-30s  %s\n" "$idx" "${SERIALS[$i]}" "${STATES[$i]}"
done

# Devices not in "device" state can't be used
echo ""
AVAILABLE_SERIALS=()
AVAILABLE_INDICES=()
for i in "${!SERIALS[@]}"; do
  if [[ "${STATES[$i]}" == "device" ]]; then
    AVAILABLE_SERIALS+=("${SERIALS[$i]}")
    AVAILABLE_INDICES+=($((i + 1)))
  else
    warn "Device ${SERIALS[$i]} is in state '${STATES[$i]}' — cannot target"
  fi
done

if [[ ${#AVAILABLE_SERIALS[@]} -eq 0 ]]; then
  err "No devices in 'device' state. Authorize via USB debugging first."
  exit 1
fi

# ─── Step 2: Let user pick devices ───────────────────────────────────
echo ""
if [[ ${#AVAILABLE_SERIALS[@]} -eq 1 ]]; then
  info "Only one device available, targeting it automatically: ${AVAILABLE_SERIALS[0]}"
  TARGET_INDICES=( "${AVAILABLE_INDICES[0]}" )
else
  while true; do
    read -r -p "$(info "Enter device number(s) to target (space-separated, e.g. '2 3 4'): ")" raw_input
    # If empty, re-prompt
    [[ -z "$raw_input" ]] && continue

    # Parse space-separated numbers
    read -ra raw_indices <<< "$raw_input"
    TARGET_INDICES=()
    valid=true
    for idx in "${raw_indices[@]}"; do
      if [[ ! "$idx" =~ ^[0-9]+$ ]] || (( idx < 1 || idx > ${#SERIALS[@]} )); then
        err "Invalid number: $idx (must be 1–${#SERIALS[@]})"
        valid=false
        break
      fi
      # Check it's in available state
      found=false
      for av in "${AVAILABLE_INDICES[@]}"; do
        if [[ "$idx" -eq "$av" ]]; then
          found=true
          break
        fi
      done
      if ! $found; then
        err "Device #$idx is not in 'device' state — cannot target"
        valid=false
        break
      fi
      TARGET_INDICES+=("$idx")
    done
    $valid && break
  done
fi

# Resolve serial numbers
TARGET_SERIALS=()
for idx in "${TARGET_INDICES[@]}"; do
  TARGET_SERIALS+=( "${SERIALS[$((idx - 1))]}" )
done

echo ""
info "Will target device(s):"
for s in "${TARGET_SERIALS[@]}"; do
  echo "    • $s"
done

# ─── Step 3: Show what will be uninstalled ───────────────────────────
echo ""
info "The following ${#APP_LIST[@]} app(s) will be uninstalled for ${#TARGET_SERIALS[@]} device(s):"
echo ""
for entry in "${APP_LIST[@]}"; do
  IFS='|' read -r pkg name <<< "$entry"
  printf "    • %-50s %s\n" "$pkg" "$name"
done

echo ""
warn "───────────────────────────────────────────────────────────────"
warn "  Google Messages (RCS) — IMPORTANT"
warn ""
warn "  Uninstalling Google Messages will permanently disable RCS"
warn "  (Rich Communication Services) on this device."
warn ""
warn "  Google may hold your phone number registered for RCS for"
warn "  several days. If you switch to another SMS app (e.g. Fossify"
warn "  Messages), RCS messages from iPhone users may still route to"
warn "  Google's servers and be lost."
warn ""
warn "  RECOMMENDED: Before running this script, open Google Messages,"
warn "  go to Settings → RCS chats → disable RCS. Wait a few days"
warn "  before uninstalling."
warn "───────────────────────────────────────────────────────────────"
echo ""
echo -e "  ${CYAN}1)${NC} Skip Google Messages — keep it for now, rerun script later to remove"
echo -e "  ${CYAN}2)${NC} RCS already disabled / I accept the risk — uninstall everything now"
echo ""
read -r -p "$(info "Choose [1/2] (default: 1): ")" rcs_choice
echo ""

if [[ "$rcs_choice" != "2" ]]; then
  warn "Skipping Google Messages for this run."
  # Rebuild APP_LIST without Google Messages
  FILTERED_APP_LIST=()
  for entry in "${APP_LIST[@]}"; do
    pkg="${entry%%|*}"
    if [[ "$pkg" != "com.google.android.apps.messaging" ]]; then
      FILTERED_APP_LIST+=("$entry")
    fi
  done
else
  FILTERED_APP_LIST=( "${APP_LIST[@]}" )
fi

# ─── Step 4: Uninstall ───────────────────────────────────────────────
echo ""
for serial in "${TARGET_SERIALS[@]}"; do
  info "--- Uninstalling on $serial ---"
  for entry in "${FILTERED_APP_LIST[@]}"; do
    IFS='|' read -r pkg name <<< "$entry"
    # Check if the package is actually installed
    installed=$(adb -s "$serial" shell pm list packages 2>/dev/null | grep -c "^package:$pkg$" || true)
    if [[ "$installed" -eq 0 ]]; then
      warn "[$serial] $pkg ($name) — not installed, skipping"
      continue
    fi

    result=$(adb -s "$serial" shell pm uninstall -k --user 0 "$pkg" 2>&1 || true)
    if echo "$result" | grep -qi "success"; then
      ok "[$serial] $pkg ($name)"
    else
      err "[$serial] $pkg ($name) — $result"
    fi
  done
done

echo ""
info "Done! Some apps may still appear as 'disabled' in the launcher."
info "To restore: adb -s <serial> shell pm install-existing <package>"
