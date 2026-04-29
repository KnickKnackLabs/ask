#!/usr/bin/env bash
#
# sessions.sh — sessions runtime wrapper for ask
#
# Environment:
#   ASK_MODEL    — Provider-qualified model (e.g. "openai-codex/gpt-5.5")
#   ASK_PROVIDER — Provider prefix for unqualified --model values
#

ASK_DIR="${ASK_DIR:-${HOME}/.ask}"
HISTORY_FILE="${HISTORY_FILE:-${ASK_DIR}/history.jsonl}"
mkdir -p "${ASK_DIR}"

# Build the full prompt with optional context.
# Context first (in XML tags), question last — models focus on what's near the end.
build_prompt() {
  local prompt="$1"
  local content="${2:-}"

  if [[ -n "${content}" ]]; then
    printf '<context>\n%s\n</context>\n\n%s' "${content}" "${prompt}"
  else
    printf '%s' "${prompt}"
  fi
}

# Save a prompt to history.
save_history() {
  local full_prompt="$1"
  local session_id="${2:-}"

  if command -v jq &>/dev/null; then
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    jq -cn --arg ts "${timestamp}" --arg prompt "${full_prompt}" --arg session "${session_id}" \
      '{timestamp: $ts, prompt: $prompt} + (if $session != "" then {session: $session} else {} end)' >> "${HISTORY_FILE}"
  fi
}

resolve_model() {
  local model="${1:-}"
  local provider="${2:-}"

  model="${model:-${ASK_MODEL:-}}"
  provider="${provider:-${ASK_PROVIDER:-}}"

  if [[ -z "$model" ]]; then
    echo "error: --model is required (for example: --model openai-codex/gpt-5.5)" >&2
    return 1
  fi

  if [[ "$model" == */* ]]; then
    printf '%s\n' "$model"
    return 0
  fi

  if [[ -n "$provider" ]]; then
    printf '%s/%s\n' "$provider" "$model"
    return 0
  fi

  echo "error: --model must be provider-qualified (for example: openai-codex/gpt-5.5)" >&2
  return 1
}

require_sessions() {
  if ! command -v sessions &>/dev/null; then
    echo "error: sessions not found — install from https://github.com/KnickKnackLabs/sessions" >&2
    return 1
  fi
}

new_ask_session() {
  local name output status session_id
  name="ask-$(date -u +"%Y%m%d-%H%M%S")"

  if output=$(sessions new "$name" --cwd "$PWD" --meta tool=ask 2>&1); then
    :
  else
    status=$?
    printf '%s\n' "$output" >&2
    return "$status"
  fi

  session_id=$(printf '%s\n' "$output" | sed -n '1p')
  if [[ -z "$session_id" ]]; then
    echo "error: sessions new returned no session id" >&2
    return 1
  fi

  printf '%s\n' "$session_id"
}

latest_ask_session() {
  local output status session_id

  if output=$(sessions list --filter session.meta.tool=ask --limit 1 --json 2>&1); then
    :
  else
    status=$?
    printf '%s\n' "$output" >&2
    return "$status"
  fi

  session_id=$(printf '%s\n' "$output" | jq -r '.[0].session_id // empty')
  if [[ -z "$session_id" ]]; then
    echo "error: no previous ask session found" >&2
    return 1
  fi

  printf '%s\n' "$session_id"
}

run_sessions() {
  local full_prompt="$1"
  local model="$2"
  local continue_session="${3:-}"
  local continue_latest="${4:-false}"
  local session_id

  require_sessions || return 1

  if [[ -n "$continue_session" ]]; then
    session_id="$continue_session"
  elif [[ "$continue_latest" == "true" ]]; then
    session_id=$(latest_ask_session) || return 1
  else
    session_id=$(new_ask_session) || return 1
  fi

  save_history "$full_prompt" "$session_id"
  env -u AGENT_IDENTITY -u DISPATCH_CONTEXT sessions wake "$session_id" --message "$full_prompt" --model "$model"
}
