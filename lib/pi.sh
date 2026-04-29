#!/usr/bin/env bash
#
# pi.sh — Pi runtime wrapper for ask
#
# Environment:
#   ASK_MODEL    — Model pattern (e.g. "sonnet", "gpt-5.4", "anthropic/claude-sonnet-4-5")
#   ASK_PROVIDER — Provider name (e.g. "anthropic", "openai", "google")
#

ASK_DIR="${ASK_DIR:-${HOME}/.ask}"
HISTORY_FILE="${HISTORY_FILE:-${ASK_DIR}/history.jsonl}"
mkdir -p "${ASK_DIR}"

# Build the full prompt with optional context
# Context first (in XML tags), question last — models focus on what's near the end
build_prompt() {
  local prompt="$1"
  local content="${2:-}"

  if [[ -n "${content}" ]]; then
    printf '<context>\n%s\n</context>\n\n%s' "${content}" "${prompt}"
  else
    printf '%s' "${prompt}"
  fi
}

# Save a prompt to history
save_history() {
  local full_prompt="$1"

  if command -v jq &>/dev/null; then
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    jq -cn --arg ts "${timestamp}" --arg prompt "${full_prompt}" \
      '{timestamp: $ts, prompt: $prompt}' >> "${HISTORY_FILE}"
  fi
}

# Run pi with the prompt
run_pi() {
  local full_prompt="$1"

  if ! command -v pi &>/dev/null; then
    echo "error: pi not found — install from https://github.com/anthropics/pi" >&2
    return 1
  fi

  save_history "${full_prompt}"

  local -a pi_args=(-p "${full_prompt}" --no-session)

  if [[ -n "${ASK_PROVIDER:-}" ]]; then
    pi_args+=(--provider "${ASK_PROVIDER}")
  fi

  if [[ -n "${ASK_MODEL:-}" ]]; then
    pi_args+=(--model "${ASK_MODEL}")
  fi

  pi "${pi_args[@]}"
}
