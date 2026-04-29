#!/usr/bin/env bash
#
# history.sh — History management
#

ASK_DIR="${HOME}/.ask"
HISTORY_FILE="${ASK_DIR}/history.jsonl"

# List recent history entries (most recent first)
list_history() {
  local limit="${1:-20}"

  if [[ ! -f "${HISTORY_FILE}" ]]; then
    echo "No history yet."
    return 0
  fi

  # Read entries, reverse (most recent first), limit
  tail -"${limit}" "${HISTORY_FILE}" | jq -r '.timestamp + " | " + (.prompt | split("\n")[0] | .[0:80])' | tail -r
}

# Get a specific history entry's full prompt
get_history_entry() {
  local index="$1"

  if [[ ! -f "${HISTORY_FILE}" ]]; then
    return 1
  fi

  tail -r "${HISTORY_FILE}" | sed -n "${index}p" | jq -r '.prompt'
}
