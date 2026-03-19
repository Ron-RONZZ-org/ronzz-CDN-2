#!/usr/bin/env bash
set -e

ZIP_URL="https://github.com/Makeblock-official/Makeblock-Libraries/archive/master.zip"
TMP_DIR="/tmp/makeblock_install"
ARDUINO_LIB="$HOME/Arduino/libraries"

echo "Preparing temporary directory..."
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"
cd "$TMP_DIR"

echo "Downloading Makeblock library..."
wget -O makeblock.zip "$ZIP_URL"

echo "Extracting..."
unzip -q makeblock.zip

echo "Ensuring Arduino library directory exists..."
mkdir -p "$ARDUINO_LIB"

echo "Installing library..."
rm -rf "$ARDUINO_LIB/makeblock"
mv Makeblock-Libraries-master "$ARDUINO_LIB/makeblock"

echo "Library installed at:"
echo "$ARDUINO_LIB/makeblock"

echo
echo "Testing detection with arduino-cli:"
arduino-cli lib list | grep -i makeblock || echo "Library installed."

echo "Done."

