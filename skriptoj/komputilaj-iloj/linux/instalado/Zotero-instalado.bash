#!/usr/bin/env bash
#
# install-zotero.sh
# Downloads Zotero (linux x86_64), extracts it, and installs to /opt/zotero.
# Robust detection of the downloaded filename/version and archive type.
#
# Usage: sudo ./install-zotero.sh
#

set -euo pipefail

ZOTERO_URL="https://www.zotero.org/download/client/dl?channel=release&platform=linux-x86_64"

# Prepare a temporary working directory
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

cd "$TMPDIR"

echo "Downloading Zotero from: $ZOTERO_URL"

# Download into a safe temporary filename, capture headers if possible.
downloaded_tmp="zotero_download.bin"
headers_tmp="zotero_headers.txt"

if command -v curl >/dev/null 2>&1; then
    # -L follow redirects, -s silent, -S show errors, -D capture headers, -o write to file
    curl -L -s -S -D "$headers_tmp" -o "$downloaded_tmp" "$ZOTERO_URL"
elif command -v wget >/dev/null 2>&1; then
    # wget with content-disposition may write the real filename; capture to a temp name if necessary
    # Use -nv to show some progress without excess noise
    wget --content-disposition -nv -O "$downloaded_tmp" "$ZOTERO_URL" 2> "$headers_tmp" || true
else
    echo "Error: neither curl nor wget is installed. Please install curl or wget and re-run." >&2
    exit 1
fi

# Try to obtain the filename from Content-Disposition (if provided)
downloaded_archive=""
if [ -f "$headers_tmp" ]; then
    # Look for filename= in headers (handles several possible formats)
    # Examples:
    # Content-Disposition: attachment; filename="Zotero-8.0.3_linux-x86_64.tar.xz"
    # or: Content-Disposition: filename=Zotero-8.0.3_linux-x86_64.tar.xz
    fname="$(sed -n 's/.*[Ff]ilename *= *"\?\([^\";]*\)"?.*/\1/p' "$headers_tmp" | tr -d '\r' | head -n1 || true)"
    if [ -n "$fname" ]; then
        # Move temporary download to the filename suggested by server
        mv -f "$downloaded_tmp" "$fname"
        downloaded_archive="$fname"
    fi
fi

# If we still don't have a download filename, attempt to detect archive type and give a sensible extension
if [ -z "$downloaded_archive" ]; then
    # Determine type using 'file' if available, otherwise try tar directly
    if command -v file >/dev/null 2>&1; then
        ftype="$(file -b --mime-type "$downloaded_tmp" || true)"
        case "$ftype" in
            application/x-xz|application/x-compressed-tar)
                mv -f "$downloaded_tmp" "Zotero-latest.tar.xz"
                downloaded_archive="Zotero-latest.tar.xz"
                ;;
            application/gzip)
                mv -f "$downloaded_tmp" "Zotero-latest.tar.gz"
                downloaded_archive="Zotero-latest.tar.gz"
                ;;
            application/x-bzip2)
                mv -f "$downloaded_tmp" "Zotero-latest.tar.bz2"
                downloaded_archive="Zotero-latest.tar.bz2"
                ;;
            application/x-tar)
                mv -f "$downloaded_tmp" "Zotero-latest.tar"
                downloaded_archive="Zotero-latest.tar"
                ;;
            *)
                # Unknown mime type: try tar -tf; if that fails, keep raw name and proceed to detection below
                if tar -tf "$downloaded_tmp" >/dev/null 2>&1; then
                    mv -f "$downloaded_tmp" "Zotero-latest.tar"
                    downloaded_archive="Zotero-latest.tar"
                else
                    # leave as-is (some servers may have saved with query-string name)
                    # find any regular file other than headers_tmp
                    for f in *; do
                        [ -f "$f" ] || continue
                        [ "$f" = "$headers_tmp" ] && continue
                        downloaded_archive="$f"
                        break
                    done
                fi
                ;;
        esac
    else
        # No 'file' command: try tar test, otherwise pick first regular file
        if tar -tf "$downloaded_tmp" >/dev/null 2>&1; then
            mv -f "$downloaded_tmp" "Zotero-latest.tar"
            downloaded_archive="Zotero-latest.tar"
        else
            for f in *; do
                [ -f "$f" ] || continue
                [ "$f" = "$headers_tmp" ] && continue
                downloaded_archive="$f"
                break
            done
        fi
    fi
fi

# Final sanity check: ensure we found a candidate
if [ -z "${downloaded_archive:-}" ] || [ ! -f "$downloaded_archive" ]; then
    echo "Error: could not find downloaded Zotero archive in $TMPDIR" >&2
    echo "Directory listing for debugging:"
    ls -la "$TMPDIR" || true
    exit 1
fi

# If the filename still looks like a query (contains ?), normalize by replacing ? with _
if echo "$downloaded_archive" | grep -q '[?]'; then
    safe_name="$(echo "$downloaded_archive" | tr '?' '_' | tr '&' '_' | tr '=' '_' )"
    mv -f "$downloaded_archive" "$safe_name"
    downloaded_archive="$safe_name"
fi

# Extract version from common naming pattern: Zotero-<version>_linux-x86_64.tar.*
version="$(echo "$downloaded_archive" | sed -n 's/^Zotero-\([0-9][^_]*\)_.*$/\1/p' || true)"
if [ -z "$version" ]; then
    # try to extract digits like 8.0.3 from any part of the filename
    version="$(echo "$downloaded_archive" | sed -n 's/.*\([0-9]\+\(\.[0-9]\+\)*\).*/\1/p' || true)"
fi
if [ -z "$version" ]; then
    version="unknown"
fi

echo "Downloaded archive: $downloaded_archive (detected version: $version)"
echo
echo "# decompressing the archive takes time. It will take a moment before sudo password is demanded."
echo

# Try to determine top-level directory inside the archive (works with tar archives)
topdir=""
if tar -tf "$downloaded_archive" >/dev/null 2>&1; then
    # find the first path that looks like a top-level directory (non-empty)
    topdir="$(tar -tf "$downloaded_archive" | awk -F/ 'NF{print $1; exit}' || true)"
fi

# Extract archive (this may take a while)
tar -xf "$downloaded_archive"

# If we couldn't determine topdir earlier, try to find a sensible extracted directory
if [ -z "$topdir" ] || [ ! -d "$topdir" ]; then
    # Find directories created in TMPDIR (excluding . and ..). Prefer those starting with Zotero or the largest one.
    dirs=(*/)
    # Normalize (remove trailing /)
    candidate=""
    for d in "${dirs[@]:-}"; do
        d="${d%/}"
        # skip the headers file and downloaded_tmp (they are files)
        [ -d "$d" ] || continue
        if [[ "$d" == Zotero* ]] || [[ "$d" == zotero* ]]; then
            candidate="$d"
            break
        fi
        # keep a fallback candidate
        if [ -z "$candidate" ]; then
            candidate="$d"
        fi
    done
    topdir="$candidate"
fi

if [ -z "$topdir" ] || [ ! -d "$topdir" ]; then
    echo "Error: could not determine the extracted top-level directory after extracting $downloaded_archive" >&2
    echo "Contents of $TMPDIR:"
    ls -la "$TMPDIR"
    exit 1
fi

echo "Preparing to install Zotero from '$topdir' to /opt/zotero"
echo "You will be prompted for your sudo password for the installation steps (remove and move to /opt, create symlinks)."

# Remove any previous installation and move the new one into place
sudo rm -rf /opt/zotero
sudo mv "$topdir" /opt/zotero

# Create or update symlinks
sudo ln -sf /opt/zotero/set_launcher_icon /usr/local/bin/zotero-set-icon
sudo ln -sf /opt/zotero/zotero /usr/local/bin/zotero

# Try to set the launcher icon now (non-fatal if it fails)
if [ -x /opt/zotero/set_launcher_icon ]; then
    /opt/zotero/set_launcher_icon || true
fi

# Register desktop entry for current user (respect SUDO_USER if run with sudo)
USER_HOME="$HOME"
if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
    # When running as sudo, place desktop entry for the invoking user
    USER_HOME="$(getent passwd "$SUDO_USER" | cut -d: -f6)"
fi

mkdir -p "$USER_HOME/.local/share/applications"
ln -sf /opt/zotero/zotero.desktop "$USER_HOME/.local/share/applications/zotero.desktop"

echo
echo "Zotero installation complete. Version detected: $version"
echo "Executable symlink: /usr/local/bin/zotero"
echo "Desktop entry: $USER_HOME/.local/share/applications/zotero.desktop"
echo
echo "Cleanup: temporary files removed from $TMPDIR (trap will remove on exit)."

