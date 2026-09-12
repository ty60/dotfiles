#!/usr/bin/env bash
# Recover Logi Options+ when it hangs on the splash screen.
#
# The Logi auto-updater silently reinstalls the package roughly once a month.
# Its postinstall script kills the running processes and rewrites
# /Library/LaunchAgents/com.logi.optionsplus.plist, but never starts the agent
# again, so com.logi.cp-dev-mgr stays loaded-but-not-running until the next
# login. The front-end app waits forever for that agent and never gets past
# "Initializing application".
#
# This script starts the agent and restarts the front-end app.

set -euo pipefail

readonly AGENT_LABEL="com.logi.cp-dev-mgr"
readonly AGENT_SERVICE="gui/$(id -u)/${AGENT_LABEL}"
readonly APP_NAME="logioptionsplus"
readonly APP_BUNDLE="/Applications/${APP_NAME}.app"

log() {
  printf '==> %s\n' "$*"
}

if ! launchctl print "$AGENT_SERVICE" >/dev/null 2>&1; then
  echo "error: ${AGENT_LABEL} is not loaded in ${AGENT_SERVICE}." >&2
  echo "       Logi Options+ may not be installed, or a reboot is needed." >&2
  exit 1
fi

log "Quitting ${APP_NAME}"
osascript -e "quit app \"${APP_NAME}\"" >/dev/null 2>&1 || true
sleep 2
# The Electron helpers can outlive the main process; make sure they are gone.
pkill -f "${APP_BUNDLE}/Contents/" >/dev/null 2>&1 || true
sleep 1

# -k restarts the agent if it is already running (it may be wedged rather than
# absent), so this is safe in both cases.
log "Restarting ${AGENT_LABEL}"
launchctl kickstart -k -p "$AGENT_SERVICE"
sleep 3

if ! launchctl print "$AGENT_SERVICE" 2>/dev/null | grep -qE '^[[:space:]]*state = running'; then
  echo "error: ${AGENT_LABEL} did not stay running." >&2
  echo "       Check: launchctl print ${AGENT_SERVICE}" >&2
  exit 1
fi

log "Launching ${APP_NAME}"
open -a "$APP_BUNDLE"

log "Done. The app should now get past the splash screen."
