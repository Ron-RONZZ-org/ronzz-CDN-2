#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────────────
# fossify.sh — Install FOSS replacements (Fossify suite + Thunderbird
#              + ReVanced Manager) on one or more Android devices
# Requires: fdroidcl (https://github.com/Hoverth/fdroidcl)
# Usage:    ./fossify.sh
# ─────────────────────────────────────────────────────────────────────

FOSSIFY_APPS=(
  "org.fossify.phone|Fossify Phone"
  "org.fossify.contacts|Fossify Contacts"
  "org.fossify.gallery|Fossify Gallery (Photos replacement)"
  "org.fossify.calendar|Fossify Calendar"
  "org.fossify.clock|Fossify Clock"
  "org.fossify.messages|Fossify Messages"
  "org.fossify.filemanager|Fossify File Manager"
  "org.fossify.notes|Fossify Notes"
)

FDROID_APPS=(
  "net.thunderbird.android|Thunderbird Email"
  "org.fdroid.fdroid|F-Droid Client"
  "app.comaps.fdroid|Comaps (maps/navigation)"
  "swati4star.createpdf|PDF Converter"
  "com.secuso.privacyFriendlyCodeScanner|Privacy Friendly Code Scanner"
  "at.tomtasche.reader|Document Reader"
)

# ReVanced Manager — NOT on F-Droid; downloaded from GitHub releases
REVANCED_MANAGER_URL="https://api.github.com/repos/ReVanced/revanced-manager/releases/latest"

# ─── Colors ──────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info()  { echo -e "${CYAN}[INFO]${NC}  $*"; }
ok()    { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
err()   { echo -e "${RED}[ERR]${NC}   $*"; }

# ─── Temp directory (cleaned up on exit) ──────────────────────────────
TMPDIR=$(mktemp -d /tmp/fossify-install-XXXXXX)
trap "rm -rf '$TMPDIR'" EXIT

# ─── Preflight: check / auto-install fdroidcl ────────────────────────
FDRCIDCL_INSTALL_DIR="${FDRCIDCL_INSTALL_DIR:-$HOME/.local/bin}"

ensure_fdroidcl() {
  if command -v fdroidcl &>/dev/null; then
    ok "fdroidcl found: $(fdroidcl version 2>/dev/null || echo 'unknown')"
    return 0
  fi

  info "fdroidcl is not installed."
  echo ""
  info "This script uses fdroidcl (https://github.com/Hoverth/fdroidcl) to"
  info "install apps from the F-Droid repository."
  echo ""

  read -r -p "$(info "auto-install fdroidcl to ${FDRCIDCL_INSTALL_DIR}/ (~12 MB) [Y/n]? ")" confirm
  if [[ ! "$confirm" =~ ^[Yy]$ ]] && [[ -n "$confirm" ]]; then
    echo ""
    warn "Install it manually, then re-run this script:"
    warn "  go install mvdan.cc/fdroidcl@latest"
    warn "  # or: https://github.com/Hoverth/fdroidcl/releases"
    exit 1
  fi

  # --- Detect OS and architecture ---
  os=$(uname -s)
  arch=$(uname -m)

  case "$os" in
    Linux)  os_asset="linux" ;;
    Darwin) os_asset="darwin" ;;
    *)
      err "Unsupported OS: $os"
      err "Install fdroidcl manually from: https://github.com/Hoverth/fdroidcl/releases"
      exit 1
      ;;
  esac

  case "$arch" in
    x86_64|amd64) arch_asset="amd64" ;;
    aarch64|arm64) arch_asset="arm64" ;;
    *)
      err "Unsupported architecture: $arch"
      err "Install fdroidcl manually from: https://github.com/Hoverth/fdroidcl/releases"
      exit 1
      ;;
  esac

  asset_suffix="${os_asset}_${arch_asset}"
  info "Detected: ${os}/${arch} → looking for asset '*${asset_suffix}'"

  # --- Fetch latest release info from GitHub API ---
  info "Fetching latest release info from GitHub…"
  release_json=$(curl -sfL "https://api.github.com/repos/Hoverth/fdroidcl/releases/latest" 2>/dev/null || true)
  if [[ -z "$release_json" ]]; then
    err "Failed to reach GitHub API (rate-limited or no internet)."
    err "Install fdroidcl manually, then re-run:"
    err "  go install mvdan.cc/fdroidcl@latest"
    exit 1
  fi

  # Extract the raw binary asset URL and SHA256 for our platform
  # We want the non-.gz / non-.zip asset matching our suffix
  asset_info=$(echo "$release_json" \
    | python3 -c "
import sys, json
data = json.load(sys.stdin)
suffix = '${asset_suffix}'
for a in data.get('assets', []):
    name = a['name']
    if name.endswith('.gz') or name.endswith('.zip'):
        continue
    if suffix in name:
        print(f\"{a['browser_download_url']}|{a['digest'].split(':')[1]}\")
        break
" 2>/dev/null || true)

  download_url="${asset_info%%|*}"
  expected_hash="${asset_info##*|}"

  if [[ -z "$download_url" || -z "$expected_hash" ]]; then
    err "Could not find a ${os_asset}/${arch_asset} binary in the latest release."
    err "Install fdroidcl manually, then re-run:"
    err "  go install mvdan.cc/fdroidcl@latest"
    exit 1
  fi

  tag=$(echo "$release_json" | python3 -c "import sys,json; print(json.load(sys.stdin)['tag_name'])" 2>/dev/null || echo "unknown")
  info "Latest version: $tag"

  # --- Ensure install directory exists ---
  mkdir -p "$FDRCIDCL_INSTALL_DIR"

  # Download to TMPDIR so the main EXIT trap cleans it up
  info "Downloading (~12 MB)…"
  tmpfile="$TMPDIR/fdroidcl-download"
  curl -sfL "$download_url" -o "$tmpfile" || {
    err "Download failed."
    exit 1
  }

  # --- Verify SHA256 ---
  computed_hash=$(sha256sum "$tmpfile" | cut -d' ' -f1)
  if [[ "$computed_hash" != "$expected_hash" ]]; then
    err "SHA256 mismatch!"
    err "  Expected: $expected_hash"
    err "  Computed: $computed_hash"
    err "  Aborting — download may be corrupted or tampered with."
    exit 1
  fi
  ok "SHA256 verified"

  # --- Install ---
  chmod +x "$tmpfile"
  mv "$tmpfile" "$FDRCIDCL_INSTALL_DIR/fdroidcl"

  # Make sure the install dir is in PATH for this session
  hash -r 2>/dev/null || true
  export PATH="$FDRCIDCL_INSTALL_DIR:$PATH"

  if command -v fdroidcl &>/dev/null; then
    ok "fdroidcl installed to ${FDRCIDCL_INSTALL_DIR}/fdroidcl ($(fdroidcl version 2>/dev/null || echo 'unknown'))"
  else
    err "Installation completed but fdroidcl not found in PATH."
    err "  Add the following to your shell config:"
    err "  export PATH=\"\$HOME/.local/bin:\$PATH\""
    exit 1
  fi
}

info "Checking prerequisites…"
ensure_fdroidcl

# ─── Step 1: Verify ADB devices ──────────────────────────────────────
info "Checking for connected ADB devices…"
DEVICES_OUTPUT=$(adb devices 2>/dev/null | tail -n +2 || true)

if [[ -z "$DEVICES_OUTPUT" ]]; then
  err "No ADB devices found."
  exit 1
fi

SERIALS=()
STATES=()
while IFS= read -r line; do
  [[ -z "$line" ]] && continue
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
    [[ -z "$raw_input" ]] && continue

    read -ra raw_indices <<< "$raw_input"
    TARGET_INDICES=()
    valid=true
    for idx in "${raw_indices[@]}"; do
      if [[ ! "$idx" =~ ^[0-9]+$ ]] || (( idx < 1 || idx > ${#SERIALS[@]} )); then
        err "Invalid number: $idx (must be 1–${#SERIALS[@]})"
        valid=false
        break
      fi
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

TARGET_SERIALS=()
for idx in "${TARGET_INDICES[@]}"; do
  TARGET_SERIALS+=( "${SERIALS[$((idx - 1))]}" )
done

echo ""
info "Will target device(s):"
for s in "${TARGET_SERIALS[@]}"; do
  echo "    • $s"
done

# ─── Step 3: Show install plan ───────────────────────────────────────
echo ""
ALL_APP_NAMES=()
for entry in "${FOSSIFY_APPS[@]}"; do
  IFS='|' read -r pkg name <<< "$entry"
  ALL_APP_NAMES+=("$name")
done
for entry in "${FDROID_APPS[@]}"; do
  IFS='|' read -r pkg name <<< "$entry"
  ALL_APP_NAMES+=("$name")
done

info "The following will be installed on ${#TARGET_SERIALS[@]} device(s):"
echo ""
echo "  ── Fossify Suite (F-Droid) ──"
for entry in "${FOSSIFY_APPS[@]}"; do
  IFS='|' read -r pkg name <<< "$entry"
  printf "    • %-40s %s\n" "$pkg" "$name"
done
echo "  ── Other (F-Droid) ──"
for entry in "${FDROID_APPS[@]}"; do
  IFS='|' read -r pkg name <<< "$entry"
  printf "    • %-40s %s\n" "$pkg" "$name"
done
echo "  ── GitHub (direct APK) ──"
echo "    • app.revanced.manager.flutter     ReVanced Manager"

echo ""
read -r -p "$(warn "Proceed with installation? [y/N]: ")" confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
  info "Cancelled by user."
  exit 0
fi

# ─── Step 4: Update F-Droid index ────────────────────────────────────
echo ""
info "Updating F-Droid index…"
fdroidcl update 2>&1 | sed 's/^/  /'

# ─── Step 5: Cache / download ReVanced Manager APK ──────────────────
CACHE_DIR="$HOME/.cache/fossify-install"
mkdir -p "$CACHE_DIR"

REVANCED_VERSION_FILE="$CACHE_DIR/revanced-manager-version.txt"
REVANCED_APK="$CACHE_DIR/revanced-manager.apk"

echo ""
info "Checking latest ReVanced Manager version on GitHub…"
release_json=$(curl -sfL "$REVANCED_MANAGER_URL" 2>/dev/null || true)

if [[ -z "$release_json" ]]; then
  warn "Could not reach GitHub API (rate-limited or no internet)."
  if [[ -f "$REVANCED_APK" && -s "$REVANCED_APK" ]]; then
    info "  Using cached APK from previous run."
  else
    warn "  No cached APK available. Skipping ReVanced Manager."
    REVANCED_APK=""
  fi
else
  latest_tag=$(echo "$release_json" | python3 -c "import sys,json; print(json.load(sys.stdin)['tag_name'])" 2>/dev/null || echo "unknown")
  info "  Latest: $latest_tag"

  cached_tag=""
  [[ -f "$REVANCED_VERSION_FILE" ]] && cached_tag=$(cat "$REVANCED_VERSION_FILE")

  if [[ "$latest_tag" == "$cached_tag" && -f "$REVANCED_APK" && -s "$REVANCED_APK" ]]; then
    ok "ReVanced Manager $latest_tag — up to date, using cached APK ($(du -h "$REVANCED_APK" | cut -f1))"
  else
    download_url=$(echo "$release_json" \
      | python3 -c "
import sys, json
data = json.load(sys.stdin)
assets = data.get('assets', [])
urls = [a['browser_download_url'] for a in assets if a['name'].endswith('.apk')]
if urls:
    print(urls[0])
" 2>/dev/null || true)

    if [[ -z "$download_url" ]]; then
      warn "  Could not determine APK URL."
      if [[ -f "$REVANCED_APK" && -s "$REVANCED_APK" ]]; then
        info "  Using cached APK from previous run."
      else
        warn "  No cached APK. Skipping ReVanced Manager."
        REVANCED_APK=""
      fi
    else
      info "  Downloading: $(basename "$download_url")"
      curl -sfL "$download_url" -o "$REVANCED_APK" || true
      if [[ -f "$REVANCED_APK" && -s "$REVANCED_APK" ]]; then
        echo "$latest_tag" > "$REVANCED_VERSION_FILE"
        ok "ReVanced Manager $latest_tag cached ($(du -h "$REVANCED_APK" | cut -f1))"
      else
        warn "  Download failed. Skipping ReVanced Manager."
        REVANCED_APK=""
      fi
    fi
  fi
fi

# ─── Step 6: Prepare package list ────────────────────────────────────
ALL_FDROID_PKGS=()
for entry in "${FOSSIFY_APPS[@]}"; do
  IFS='|' read -r pkg name <<< "$entry"
  ALL_FDROID_PKGS+=("$pkg")
done
for entry in "${FDROID_APPS[@]}"; do
  IFS='|' read -r pkg name <<< "$entry"
  ALL_FDROID_PKGS+=("$pkg")
done

# ─── Step 7: Install on all devices in parallel ──────────────────────
# ReVanced Manager install on each device runs in background during
# the fdroidcl loop — both ADB channels are independent.

install_fdroid_apps() {
  local serial="$1"
  export ANDROID_SERIAL="$serial"
  for pkg in "${ALL_FDROID_PKGS[@]}"; do
    if adb -s "$serial" shell pm list packages 2>/dev/null | grep -q "^package:$pkg$"; then
      echo "[SKIP] $pkg — already installed"
      continue
    fi
    result=$(fdroidcl install "$pkg" 2>&1 || true)
    if echo "$result" | grep -qi "already up to date"; then
      echo "[OK]   $pkg — already installed"
    elif echo "$result" | grep -qi "Installing"; then
      echo "[OK]   $pkg"
    else
      echo "[ERR]  $pkg — $(echo "$result" | tail -1)"
    fi
  done
}

echo ""
if [[ ${#TARGET_SERIALS[@]} -eq 1 ]]; then
  # ── Single device — run inline ──
  serial="${TARGET_SERIALS[0]}"
  info "━━━ Installing on $serial ━━━"

  # Kick off ReVanced install in background if needed
  revanced_out="$TMPDIR/revanced-result.txt"
  revanced_pid=""
  if [[ -n "${REVANCED_APK:-}" && -f "$REVANCED_APK" ]] && \
     ! adb -s "$serial" shell pm list packages 2>/dev/null | grep -q "^package:app.revanced.manager.flutter$"; then
    ( adb -s "$serial" install -r "$REVANCED_APK" 2>&1 || true ) > "$revanced_out" &
    revanced_pid=$!
  fi

  # Run fdroidcl installs while ReVanced installs in background
  info "Installing ${#ALL_FDROID_PKGS[@]} app(s) from F-Droid…"
  install_fdroid_apps "$serial"

  # Collect ReVanced result
  if [[ -n "$revanced_pid" ]]; then
    wait "$revanced_pid" 2>/dev/null || true
    if grep -qi "success" "$revanced_out" 2>/dev/null; then
      ok "[$serial] ReVanced Manager"
    else
      err "[$serial] ReVanced Manager — $(cat "$revanced_out" 2>/dev/null || echo 'unknown error')"
    fi
  elif [[ -n "${REVANCED_APK:-}" && -f "$REVANCED_APK" ]]; then
    ok "[$serial] ReVanced Manager — already installed, skipping"
  fi

else
  # ── Multiple devices — full parallel ──
  info "Installing on ${#TARGET_SERIALS[@]} devices in parallel…"
  PARALLEL_DIR="$TMPDIR/parallel"
  mkdir -p "$PARALLEL_DIR"
  pids=()

  for serial in "${TARGET_SERIALS[@]}"; do
    (
      log() { echo -e "${CYAN}[INFO]${NC}  $*"; }
      ok()  { echo -e "${GREEN}[OK]${NC}    $*"; }
      err() { echo -e "${RED}[ERR]${NC}   $*"; }

      log "━━━ Installing on $serial ━━━"

      # Kick off ReVanced install in background inside this subshell
      revanced_out="$TMPDIR/revanced-$serial.txt"
      revanced_pid=""
      if [[ -n "${REVANCED_APK:-}" && -f "$REVANCED_APK" ]] && \
         ! adb -s "$serial" shell pm list packages 2>/dev/null | grep -q "^package:app.revanced.manager.flutter$"; then
        ( adb -s "$serial" install -r "$REVANCED_APK" 2>&1 || true ) > "$revanced_out" &
        revanced_pid=$!
      fi

      # Run fdroidcl installs in parallel with ReVanced
      log "Installing ${#ALL_FDROID_PKGS[@]} app(s) from F-Droid…"
      export ANDROID_SERIAL="$serial"
      for pkg in "${ALL_FDROID_PKGS[@]}"; do
        if adb -s "$serial" shell pm list packages 2>/dev/null | grep -q "^package:$pkg$"; then
          ok "[$serial] $pkg — already installed, skipping"
          continue
        fi
        result=$(fdroidcl install "$pkg" 2>&1 || true)
        if echo "$result" | grep -qi "already up to date"; then
          ok "[$serial] $pkg — already installed"
        elif echo "$result" | grep -qi "Installing"; then
          ok "[$serial] $pkg"
        else
          err "[$serial] $pkg — $(echo "$result" | tail -1)"
        fi
      done

      # Collect ReVanced result
      if [[ -n "$revanced_pid" ]]; then
        wait "$revanced_pid" 2>/dev/null || true
        if grep -qi "success" "$revanced_out" 2>/dev/null; then
          ok "[$serial] ReVanced Manager"
        else
          err "[$serial] ReVanced Manager — $(cat "$revanced_out" 2>/dev/null || echo 'unknown error')"
        fi
      elif [[ -n "${REVANCED_APK:-}" && -f "$REVANCED_APK" ]]; then
        ok "[$serial] ReVanced Manager — already installed, skipping"
      fi
    ) > "$PARALLEL_DIR/$serial.log" 2>&1 &
    pids+=($!)
  done

  # Wait for all parallel installs to finish
  for pid in "${pids[@]}"; do
    wait "$pid" 2>/dev/null || true
  done

  # Print results per device, in order
  for serial in "${TARGET_SERIALS[@]}"; do
    echo ""
    info "━━━ Results for $serial ━━━"
    cat "$PARALLEL_DIR/$serial.log"
  done
fi

# ─── Done ────────────────────────────────────────────────────────────
echo ""
info "Done!"
echo ""
info "Apps installed:"
for entry in "${FOSSIFY_APPS[@]}"; do
  IFS='|' read -r pkg name <<< "$entry"
  echo "    • $name ($pkg)"
done
for entry in "${FDROID_APPS[@]}"; do
  IFS='|' read -r pkg name <<< "$entry"
  echo "    • $name ($pkg)"
done
echo "    • ReVanced Manager (app.revanced.manager.flutter)"
echo ""
info "To verify: adb -s <serial> shell pm list packages | grep -E 'org\.(fossify|fdroid)|thunderbird|revanced'"
