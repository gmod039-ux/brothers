#!/bin/sh
# Builds the game to play without Godot, into build/ (which git ignores):
#
#   build/Братья-mac.zip      Братья.app for macOS, Intel and Apple chips both;
#                             signed ad hoc only, so the first launch needs
#                             «Всё равно открыть» in Privacy & Security (or
#                             xattr -dr com.apple.quarantine Братья.app)
#   build/Братья-windows.zip  Братья.exe, everything inside it
#   build/Братья-linux.zip    brothers.x86_64, likewise
#
#     sh dev/build.sh              all three
#     sh dev/build.sh macOS        one (the preset's name: macOS, Windows, Linux)
#
# Needs Godot 4.7.2 and its export templates (in the editor: Editor → Manage
# Export Templates → Download; or the .tpz from the release page). The
# presets are in export_presets.cfg: the data and the rooms (*.json, *.txt)
# go in as extra files, dev/ stays out.
set -eu
cd "$(dirname "$0")/.."
mkdir -p build/windows build/linux
# Godot is not to look inside build/: what is there is output, not source.
touch build/.gdignore
limited() { perl -e 'alarm shift; exec @ARGV' 600 "$@"; }
limited godot --headless --path . --import > /dev/null 2>&1
for preset in ${1:-macOS Windows Linux}; do
	echo "== $preset"
	out=$(limited godot --headless --path . --export-release "$preset" 2>&1) || true
	if echo "$out" | grep -qE "ERROR|SCRIPT ERROR"; then
		echo "$out" | grep -E "ERROR|at: " | head -20
		exit 1
	fi
	case $preset in
		Windows) (cd build/windows && zip -q -9 -FS ../Братья-windows.zip Братья.exe) ;;
		Linux) (cd build/linux && zip -q -9 -FS ../Братья-linux.zip brothers.x86_64) ;;
	esac
done
ls -la build/*.zip
