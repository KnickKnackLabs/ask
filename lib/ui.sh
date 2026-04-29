#!/usr/bin/env bash
#
# ui.sh — Gum UI helpers
#

# Use HISTORY_FILE from sessions.sh if set, otherwise default
HISTORY_FILE="${HISTORY_FILE:-${HOME}/.ask/history.jsonl}"

# Show a preview of content with a label
preview_content() {
  local label="$1"
  local content="$2"
  local max_lines="${3:-10}"

  local preview
  preview=$(echo "${content}" | head -"${max_lines}")
  local total_lines
  total_lines=$(echo "${content}" | wc -l | tr -d ' ')

  echo ""
  gum style --faint "${label} (${total_lines} lines)"
  gum style --border rounded --padding "1 2" --border-foreground 240 --width 80 \
    "${preview}"

  if [[ ${total_lines} -gt ${max_lines} ]]; then
    gum style --faint "... (${total_lines} lines total)"
  fi
  echo ""
}

# Get recent unique prompts (most recent first, first line only for display)
_get_recent_prompts() {
  local limit="${1:-20}"

  if [[ ! -f "${HISTORY_FILE}" ]]; then
    return
  fi

  # jq slurps, reverses (most recent first), extracts first line of each prompt
  # awk dedupes while preserving order
  jq -sr '[.[] | .prompt | split("\n")[0] | .[0:100]] | reverse | .[]' \
    "${HISTORY_FILE}" 2>/dev/null | \
    awk '!seen[$0]++' | \
    head -"${limit}"
}

# Prompt user for a question
# - gum write textarea (mini vim) — Esc/Ctrl+D to submit
# - Submit empty → history picker appears
# - History selection → pre-fills textarea for editing
prompt_user() {
  local placeholder="${1:-What would you like to ask?}"
  local header="Esc to submit • empty submit for history"

  while true; do
    # Step 1: gum write textarea — multi-line, Esc/Ctrl+D submits
    local input
    input=$(gum write \
      --placeholder "${placeholder}" \
      --char-limit 0 \
      --header "${header}" \
      --width 80) || return

    # If user typed something, return it
    if [[ -n "${input}" ]]; then
      echo "${input}"
      return
    fi

    # Step 2: empty submit → show history picker
    local prompts
    prompts=$(_get_recent_prompts 15)

    if [[ -z "${prompts}" ]]; then
      header="No history yet. Type your prompt:"
      continue
    fi

    local selected
    selected=$(echo "${prompts}" | gum filter \
      --height 10 \
      --placeholder "Search history..." \
      --header "↑↓ browse • type to filter • Esc to go back") || continue

    # Step 3: selected history → pre-fill textarea for editing
    if [[ -n "${selected}" ]]; then
      input=$(gum write \
        --placeholder "${placeholder}" \
        --char-limit 0 \
        --header "Edit and submit (Esc to send)" \
        --width 80 \
        --value "${selected}") || return

      if [[ -n "${input}" ]]; then
        echo "${input}"
        return
      fi
    fi
  done
}
