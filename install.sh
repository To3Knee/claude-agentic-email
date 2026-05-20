#!/usr/bin/env bash
# install.sh — write the claude-agentic-email channel's local config (.env).
#
# Creates ~/.claude/channels/agentic-email/.env (mode 600) so the channel can
# reach your agentic-inbox worker behind Cloudflare Access.
#
# Provide config via env vars (or source the CF creds from a JSON file):
#   AGENTIC_INBOX_BASE       worker base URL (e.g. https://inbox.example.com)        [required]
#   AGENTIC_INBOX_MAILBOX    mailbox to watch (e.g. assistant@example.com)           [required]
#   CF_ACCESS_CLIENT_ID      CF Access service-token id                              [required]
#   CF_ACCESS_CLIENT_SECRET  CF Access service-token secret                          [required]
#   AGENTIC_INBOX_FROM_NAME  outbound display name (default "Assistant")             [optional]
#   EMAIL_POLL_INTERVAL      seconds between polls (default 20)                      [optional]
#   SECRETS_FILE             JSON file {client_id, client_secret} to source creds    [optional]
#
# Example:
#   AGENTIC_INBOX_BASE=https://inbox.example.com \
#   AGENTIC_INBOX_MAILBOX=assistant@example.com \
#   CF_ACCESS_CLIENT_ID=xxx CF_ACCESS_CLIENT_SECRET=yyy \
#   bash install.sh

set -eu

STATE_DIR="${EMAIL_CHANNEL_STATE_DIR:-$HOME/.claude/channels/agentic-email}"
BASE="${AGENTIC_INBOX_BASE:-}"
MAILBOX="${AGENTIC_INBOX_MAILBOX:-}"
FROM_NAME="${AGENTIC_INBOX_FROM_NAME:-Assistant}"
POLL="${EMAIL_POLL_INTERVAL:-20}"
CID="${CF_ACCESS_CLIENT_ID:-}"
CSEC="${CF_ACCESS_CLIENT_SECRET:-}"

# Optionally source CF Access creds from a JSON file: {"client_id":"…","client_secret":"…"}
if [ -n "${SECRETS_FILE:-}" ]; then
  if [ ! -f "$SECRETS_FILE" ]; then
    echo "SECRETS_FILE not found: $SECRETS_FILE" >&2; exit 1
  fi
  CID=$(python3 -c "import json;print(json.load(open('$SECRETS_FILE')).get('client_id',''))")
  CSEC=$(python3 -c "import json;print(json.load(open('$SECRETS_FILE')).get('client_secret',''))")
fi

missing=""
[ -z "$BASE" ]    && missing="$missing AGENTIC_INBOX_BASE"
[ -z "$MAILBOX" ] && missing="$missing AGENTIC_INBOX_MAILBOX"
[ -z "$CID" ]     && missing="$missing CF_ACCESS_CLIENT_ID"
[ -z "$CSEC" ]    && missing="$missing CF_ACCESS_CLIENT_SECRET"
if [ -n "$missing" ]; then
  echo "Missing required config:$missing" >&2
  echo "Set them as env vars (see the header of this script) and re-run." >&2
  exit 1
fi

mkdir -p "$STATE_DIR"; chmod 700 "$STATE_DIR"
ENV_FILE="$STATE_DIR/.env"
umask 177
cat > "$ENV_FILE" <<EOF
AGENTIC_INBOX_BASE=$BASE
AGENTIC_INBOX_MAILBOX=$MAILBOX
AGENTIC_INBOX_FROM_NAME=$FROM_NAME
EMAIL_POLL_INTERVAL=$POLL
CF_ACCESS_CLIENT_ID=$CID
CF_ACCESS_CLIENT_SECRET=$CSEC
EOF
chmod 600 "$ENV_FILE"

echo "Wrote $ENV_FILE (mode 600)"
echo "  base:    $BASE"
echo "  mailbox: $MAILBOX"
echo "  from:    $FROM_NAME"
echo "  poll:    ${POLL}s"
echo
echo "Next:"
echo "  1) Register this directory as a plugin marketplace (one time, name 'claude-agentic-email'):"
echo "       claude plugin marketplace add \"\$(pwd)\""
echo "  2) Launch Claude Code with the channel. Custom channels aren't on the"
echo "     preview allowlist, so the dev flag is required (it only skips the allowlist):"
echo "       claude --dangerously-load-development-channels plugin:agentic-email@claude-agentic-email"
