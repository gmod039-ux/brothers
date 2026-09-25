#!/bin/sh
# Runs every automated check, each under a time limit.
#
# The limit is not optional. A headless Godot run whose script fails to parse
# does not exit -- it prints the parse error and then sits there forever, and
# a check that never returns looks exactly like a check that is still busy.
#
#     sh dev/check.sh
set -u
cd "$(dirname "$0")/.." || exit 1

LIMIT=240
failed=0

# macOS has no `timeout`; perl's alarm does the same job everywhere.
limited() { perl -e 'alarm shift; exec @ARGV' "$LIMIT" "$@"; }

# A new class_name is not known to other scripts until the project has been
# imported, so this always goes first.
echo "== import"
out=$(limited godot --headless --path . --import 2>&1)
if echo "$out" | grep -qE "SCRIPT ERROR|Parse Error|ERROR"; then
    echo "$out" | grep -E "SCRIPT ERROR|Parse Error|ERROR|at: " | head -20
    failed=1
fi

run() {
    name=$1; shift
    echo "== $name"
    # --fixed-fps: every frame is 1/60 s of game time however fast it really
    # runs, so a minute of play takes a few seconds.
    out=$(limited godot --headless --fixed-fps 60 --path . "$@" 2>&1)
    code=$?
    echo "$out" | grep -vE "^Godot Engine|^$|ObjectDB instances|resources still in use|^   at: " | sed 's/^/   /'
    if [ $code -eq 142 ]; then
        echo "   TIMED OUT after ${LIMIT}s -- look for a parse error above"
        failed=1
    elif [ $code -ne 0 ] || echo "$out" | grep -qE "SCRIPT ERROR|Parse Error|^ERROR"; then
        failed=1
    fi
}

run "data" --script res://dev/data_check.gd
run "floors" --script res://dev/floor_check.gd
run "combat" --script res://dev/combat_check.gd
run "arena, older" -- brother older demo arena seed 11 autoplay 90
# A whole floor, boss included, with nobody at the keyboard.
run "floor run, younger" -- brother younger demo seed 3 autoplay 200 need_bosses 1
run "floor run, older" -- brother older demo seed 8 autoplay 240 need_bosses 1

if [ $failed -eq 0 ]; then echo; echo "ALL OK"; else echo; echo "SOMETHING FAILED"; fi
exit $failed
