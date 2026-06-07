#!/bin/bash
# macOS notification for Claude Code events. Reads hook JSON on stdin and
# posts a notification via the "Claude Code Notification" app bundle at
# ~/Applications/Claude Code Notification.app (its own bundle ID so it can
# be allowlisted in Focus mode independently of Script Editor).
#
# Usage: notify.sh <event>            # event: "Notification" or "Stop"
#
# Wired from ~/.claude/settings.json as Notification + Stop hooks:
#   "hooks": {
#     "Notification": [{ "hooks": [{ "type": "command",
#         "command": "~/.claude/scripts/notify.sh Notification" }] }],
#     "Stop":         [{ "hooks": [{ "type": "command",
#         "command": "~/.claude/scripts/notify.sh Stop"         }] }]
#   }
#
# Manual test:
#   echo '{"message":"hi","cwd":"'"$PWD"'"}' | ./notify.sh Notification
#
# ----------------------------------------------------------------------
# Install on macOS (one-time, per machine)
# ----------------------------------------------------------------------
# 1. Build the Swift notification helper:
#
#      SCRIPTS="$(cd "$(dirname "$0")" && pwd)"
#      swiftc -O -o "$SCRIPTS/ccn-notify" "$SCRIPTS/ccn-notify.swift"
#
# 2. Create the .app bundle from scratch with a hand-written Cocoa
#    Info.plist. Do NOT use `osacompile` here — its AppleScript-applet
#    template leaves NSPrincipalClass unset / wrong, which breaks
#    multi-display banner routing on recent macOS. Then ad-hoc sign
#    and register with Launch Services:
#
#      APP="$HOME/Applications/Claude Code Notification.app"
#      rm -rf "$APP"
#      mkdir -p "$APP/Contents/MacOS"
#      cp "$SCRIPTS/ccn-notify" "$APP/Contents/MacOS/ccn-notify"
#
#      cat > "$APP/Contents/Info.plist" <<'PLIST'
#      <?xml version="1.0" encoding="UTF-8"?>
#      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
#      <plist version="1.0">
#      <dict>
#        <key>CFBundleDevelopmentRegion</key>            <string>en</string>
#        <key>CFBundleExecutable</key>                   <string>ccn-notify</string>
#        <key>CFBundleIdentifier</key>                   <string>com.ty.claude-code-notification</string>
#        <key>CFBundleInfoDictionaryVersion</key>        <string>6.0</string>
#        <key>CFBundleName</key>                         <string>Claude Code Notification</string>
#        <key>CFBundleDisplayName</key>                  <string>Claude Code Notification</string>
#        <key>CFBundlePackageType</key>                  <string>APPL</string>
#        <key>CFBundleShortVersionString</key>           <string>1.0</string>
#        <key>CFBundleVersion</key>                      <string>1</string>
#        <key>LSMinimumSystemVersion</key>               <string>11.0</string>
#        <key>LSUIElement</key>                          <true/>
#        <key>NSHighResolutionCapable</key>              <true/>
#        <key>NSPrincipalClass</key>                     <string>NSApplication</string>
#        <key>NSSupportsAutomaticGraphicsSwitching</key> <true/>
#      </dict>
#      </plist>
#      PLIST
#
#      codesign --force --sign - "$APP"
#      /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$APP"
#
# 3. Symlink this script + settings.json from the dotfiles repo:
#
#      ln -s ~/dotfiles/claude/settings.json ~/.claude/settings.json
#      ln -s ~/dotfiles/claude/scripts       ~/.claude/scripts
#
# 4. Trigger the macOS permission prompt once (foreground launch), then
#    click "Allow" on the "Claude Code Notification" notification dialog:
#
#      open -a "$APP" --args "Claude Code" "" "permission test"
#
# 5. (Optional) Allow during Focus: System Settings -> Focus -> [Focus]
#    -> Allowed Notifications -> Apps -> add "Claude Code Notification".
#
# ----------------------------------------------------------------------
# Troubleshooting: banner not showing (goes straight to Notification Center)
# ----------------------------------------------------------------------
# If notifications appear in Notification Center but no banner pops up on
# screen — especially when multiple displays are connected — macOS is
# muting the banner via "display shared" state. Confirm by running:
#
#   log stream --style compact --predicate 'process == "NotificationCenter"'
#
# and triggering a notification. A line like
#   "... muted by display state (displayShared)"
# means the OS considers the display to be mirrored/shared/recorded.
#
# Fix: System Settings -> Notifications -> scroll to the bottom ->
#   toggle ON "Allow notifications when mirroring or sharing the display."
#
# Also check for background apps that pin the shared state (Zoom, Teams,
# OBS, Loom, CleanShot, QuickTime recordings, AirPlay Receiver, Sidecar).

set -u

event="${1:-Stop}"
input="$(cat 2>/dev/null || true)"

# Suppress only when *this* Claude's tmux pane is the one the user is
# currently viewing. Outside tmux (Ghostty/iTerm2 used directly) we always
# fire so notifications from a non-focused window aren't dropped.
LOG="${CCN_DEBUG_LOG:-/tmp/claude-notify.log}"
log() { [ -n "${CCN_DEBUG:-}" ] && printf '[%s] %s\n' "$(date +%H:%M:%S)" "$*" >>"$LOG"; }

find_tmux() {
  for p in tmux /opt/homebrew/bin/tmux /usr/local/bin/tmux; do
    command -v "$p" >/dev/null 2>&1 && { echo "$p"; return 0; }
  done
  return 1
}

should_suppress() {
  local tty
  tty="$(ps -o tty= -p "$PPID" 2>/dev/null | tr -d ' \n')"
  log "PPID=$PPID hook_tty_raw=$tty"
  [ -z "$tty" ] || [ "$tty" = "??" ] && { log "no tty"; return 1; }
  case "$tty" in /dev/*) ;; *) tty="/dev/$tty" ;; esac
  local hook_tty="$tty"

  local front
  front="$(/usr/bin/osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true' 2>/dev/null)"
  log "frontmost=$front"
  case "$front" in
    iTerm2|iTerm|Ghostty|ghostty|Terminal) ;;
    *) log "not a terminal"; return 1 ;;
  esac

  local tmux_bin
  tmux_bin="$(find_tmux)" || { log "tmux not found"; return 1; }

  local info
  info="$("$tmux_bin" list-panes -a -F '#{pane_tty} #{pane_active} #{window_active} #{session_attached}' 2>/dev/null \
    | awk -v t="$hook_tty" '$1==t {print $2, $3, $4; exit}')"
  log "pane_info='$info' (hook_tty=$hook_tty)"
  [ -z "$info" ] && return 1

  local pa wa sa
  read -r pa wa sa <<<"$info"
  [ "$pa" = "1" ] && [ "$wa" = "1" ] && [ "${sa:-0}" -ge 1 ]
}

if should_suppress; then
  exit 0
fi

# Clean up stale focus scripts (older than 5 min)
find /tmp -maxdepth 1 -name 'claude-notify-focus-*.sh' -mmin +5 -delete 2>/dev/null || true

# Build a focus script so clicking the notification brings Claude's pane
# to the foreground. Walks the tmux client's process tree to identify the
# hosting terminal app, then writes a small shell script that selects the
# right tmux pane and activates the terminal.
focus_file=""
build_focus_script() {
  local tmux_bin tty target session client_pid pid comm terminal_app
  tmux_bin="$(find_tmux)" || return 1

  tty="$(ps -o tty= -p "$PPID" 2>/dev/null | tr -d ' \n')"
  [ -z "$tty" ] || [ "$tty" = "??" ] && return 1
  case "$tty" in /dev/*) ;; *) tty="/dev/$tty" ;; esac

  target="$("$tmux_bin" list-panes -a \
    -F '#{pane_tty} #{session_name}:#{window_index}.#{pane_index}' 2>/dev/null \
    | awk -v t="$tty" '$1==t {print $2; exit}')"
  [ -z "$target" ] && return 1

  session="${target%%:*}"

  # Walk tmux client's process tree to find hosting terminal app
  terminal_app=""
  client_pid="$("$tmux_bin" list-clients -t "$session" \
    -F '#{client_pid}' 2>/dev/null | head -1)"
  if [ -n "$client_pid" ]; then
    pid="$client_pid"
    while [ -n "$pid" ] && [ "$pid" != "1" ] && [ "$pid" != "0" ]; do
      comm="$(basename "$(ps -o comm= -p "$pid" 2>/dev/null)" 2>/dev/null)"
      case "$comm" in
        Ghostty|ghostty)       terminal_app="Ghostty"; break ;;
        iTerm2|iTerm2-arm64)   terminal_app="iTerm2"; break ;;
        Terminal)              terminal_app="Terminal"; break ;;
        Alacritty|alacritty)   terminal_app="Alacritty"; break ;;
        kitty)                 terminal_app="kitty"; break ;;
        WezTerm|wezterm-gui)   terminal_app="WezTerm"; break ;;
      esac
      pid="$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')"
    done
  fi
  [ -z "$terminal_app" ] && return 1

  # Validate target format (session:window.pane — integers after the colon)
  case "$target" in
    *[!A-Za-z0-9_.:-]*) return 1 ;;
  esac

  focus_file="/tmp/claude-notify-focus-$$.sh"
  # terminal_app is from the hardcoded allowlist above, so it's safe to
  # interpolate. target is validated.
  umask 077  # owner-only permissions for the focus script
  cat > "$focus_file" <<EOF
#!/bin/bash
"$tmux_bin" select-window -t "$target" 2>/dev/null
"$tmux_bin" select-pane -t "$target" 2>/dev/null
/usr/bin/osascript -e 'tell application "$terminal_app" to activate'
rm -f "$focus_file"
EOF
  chmod +x "$focus_file"
}
build_focus_script 2>/dev/null || true

# Parse hook JSON with python3 (always present on macOS). Prints "msg<TAB>subtitle".
line="$(printf '%s' "$input" | /usr/bin/python3 -c '
import json, os, sys
event = sys.argv[1]
try:
    data = json.loads(sys.stdin.read() or "{}")
except Exception:
    data = {}
msg = data.get("message") or ("Needs your input" if event == "Notification" else "Task finished")
cwd = data.get("cwd") or ""
sub = os.path.basename(cwd) if cwd else ""
print(" ".join(str(msg).split()) + "\t" + sub)
' "$event" 2>/dev/null)"

message="${line%%$'\t'*}"
subtitle="${line#*$'\t'}"
[ -z "$message" ] && message="Claude Code: $event"

title="Claude Code"
APP="$HOME/Applications/Claude Code Notification.app"

/usr/bin/open -gj -n -a "$APP" --args \
  "$title" "${subtitle:-}" "$message" "${focus_file:-}" >/dev/null 2>&1

exit 0
