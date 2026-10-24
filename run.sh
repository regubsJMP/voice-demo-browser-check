#!/bin/bash
# Runs on a GitHub macOS runner: opens probe/mac.html in Safari or Chrome (normal launch, no WebDriver — WebDriver sessions
# auto-grant the microphone and never show the prompt), presses keys and clicks through System Events / cliclick (real input =
# user gestures) and takes full-screen screenshots, so the browser's own UI (permission prompts, full screen) is visible.
# Every scenario runs on its own origin (ports 8001…8005) — a fresh permission state, like a first visit.
#   bash run.sh safari | chrome
set -u
B="${1:-safari}"; ROOT="$(cd "$(dirname "$0")" && pwd)"; OUT="$ROOT/out/$B"; mkdir -p "$OUT"
# bind to 127.0.0.1: listening on all interfaces made macOS ask "Allow Python to find devices on local networks?" over the browser
for port in 8001 8002 8003 8004 8005 8006 8007; do (cd "$ROOT/probe" && python3 -m http.server --bind 127.0.0.1 $port >/dev/null 2>&1 &); done
sleep 1
n=0
step() { echo "== $(date -u +%H:%M:%S) $*"; }
# the page puts its last three log lines into the tab title — print it next to every screenshot (readable even under a system dialog)
wtitle() { osascript -e "tell application \"System Events\" to get name of front window of process \"$PROC\"" 2>/dev/null; }
shot() { n=$((n + 1)); screencapture -x "$OUT/$(printf %02d $n)-$1.png" && echo "   shot $n: $1 | $(wtitle)"; }
key() { osascript -e "tell application \"System Events\" to keystroke \"$1\"" || echo "   keystroke $1 failed"; }
esc() { osascript -e 'tell application "System Events" to key code 53' || echo "   esc failed"; }
click() { cliclick "c:$1,$2" || echo "   click $1,$2 failed"; }
FIRST="http://localhost:8005/mac.html?onload"
step "launch $B"
if [ "$B" = safari ]; then APP=Safari; PROC=Safari; ALLOW="512,381"; open -a Safari "$FIRST"
else APP="Google Chrome"; PROC="Google Chrome"; ALLOW=""   # «open -na "Google Chrome" --args …» hung the whole step for 10 min (run 2) — start the binary directly
  nohup "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --user-data-dir=/tmp/chrome-probe --no-first-run \
    --no-default-browser-check "$FIRST" >/dev/null 2>&1 &
fi
front() { open -a "$APP"; sleep 1.5; }
go() { front; osascript -e 'tell application "System Events" to keystroke "l" using command down'; sleep 0.5; key "localhost:$1/mac.html"
  osascript -e 'tell application "System Events" to key code 36'; sleep 4; }
# «Allow» — found by its text on the screen (clicktext, Vision OCR); fixed coordinates only as a fallback
allow() { local f="${RUNNER_TEMP:-/tmp}/find.png" xy lab; [ "$B" = safari ] && lab="Allow" || lab="Allow this time"; screencapture -x "$f"
  if xy=$("$ROOT/clicktext" "$f" "$lab"); then cliclick "c:${xy% *},${xy#* }"; echo "   clicked «${lab}» at ${xy} (found by text)"
  elif [ -n "$ALLOW" ]; then click "${ALLOW%,*}" "${ALLOW#*,}"; echo "   clicked fixed $ALLOW"; else echo "   «${lab}» not found"; fi; }
sleep 12; front
step "S0 (8005): microphone asked on page load, before any click — is the prompt shown?"
shot s0-onload-prompt; allow; sleep 3; shot s0-after-allow; key 3; sleep 3; shot s0-key-fs; esc; sleep 2
step "S1 (8001): full screen first, then the microphone — is the prompt visible in full screen?"
go 8001; key 1; sleep 3; shot s1-fs-then-mic-3s; sleep 6; shot s1-fs-then-mic-9s
esc; sleep 3; shot s1-after-esc
allow; sleep 3; shot s1-after-allow
step "S2 (8002): microphone first, Allow after ~1 s, then full screen (activation window ~5 s)"
go 8002; key 2; sleep 1.5; shot s2-prompt; allow; sleep 3; shot s2-after-allow-1s; esc; sleep 2
step "S3 (8003): microphone first, Allow after ~7 s (too late for full screen), then a click on the page background"
go 8003; key 2; sleep 7; shot s3-prompt-7s; allow; sleep 3; shot s3-after-allow-7s; click 700 600; sleep 3; shot s3-after-next-click; esc; sleep 2
step "S4 (8004): file picker while in full screen"
go 8004; key 3; sleep 3; shot s4-fullscreen; key 6; sleep 3; shot s4-picker; esc; sleep 2; shot s4-after-esc
step "S6 (8006): full screen first, then audio in the same key press (does full screen use up the gesture?)"
go 8006; key 7; sleep 3; shot s6-fs-then-audio; esc; sleep 2
step "S7 (8007): audio first, then full screen"
go 8007; key 8; sleep 3; shot s7-audio-then-fs; esc; sleep 2
go 8004
step "S5 (8004): audio elements"
key 5; sleep 10; shot s5-audio
step "done: $n screenshots in $OUT"
