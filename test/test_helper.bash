#!/usr/bin/env bash

if [ -z "${MISE_CONFIG_ROOT:-}" ]; then
  echo "MISE_CONFIG_ROOT not set — run tests via: mise run test" >&2
  exit 1
fi

# Source libs for unit testing
source "$MISE_CONFIG_ROOT/lib/sessions.sh"
source "$MISE_CONFIG_ROOT/lib/clipboard.sh"

install_fake_sessions() {
  local bin_dir="$BATS_TEST_TMPDIR/bin"
  mkdir -p "$bin_dir"
  export ASK_SESSIONS_LOG="$BATS_TEST_TMPDIR/sessions.log"
  export PATH="$bin_dir:$PATH"

  cat > "$bin_dir/sessions" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >> "${ASK_SESSIONS_LOG:?}"

case "${1:-}" in
  new)
    echo "new-session-id"
    ;;
  list)
    echo '[{"session_id":"last-ask-session"}]'
    ;;
  wake)
    printf 'wake-agent-identity=%s\n' "${AGENT_IDENTITY:-}" >> "${ASK_SESSIONS_LOG:?}"
    printf 'wake-dispatch-context=%s\n' "${DISPATCH_CONTEXT:-}" >> "${ASK_SESSIONS_LOG:?}"
    printf 'wake-usage-background=%s\n' "${usage_background:-}" >> "${ASK_SESSIONS_LOG:?}"
    printf 'wake-usage-headless=%s\n' "${usage_headless:-}" >> "${ASK_SESSIONS_LOG:?}"
    printf 'wake-usage-context=%s\n' "${usage_context:-}" >> "${ASK_SESSIONS_LOG:?}"
    message=""
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --message)
          message="$2"
          shift 2
          ;;
        *)
          shift
          ;;
      esac
    done
    case "$message" in
      *pineapple*) echo "pineapple" ;;
      *answer*|*42*) echo "42" ;;
      *hello*) echo "hello" ;;
      *) echo "ok" ;;
    esac
    ;;
  *)
    echo "unexpected sessions command: $*" >&2
    exit 1
    ;;
esac
SH
  chmod +x "$bin_dir/sessions"
}

# Wrapper to run ask tasks through mise
ask() {
  cd "$MISE_CONFIG_ROOT" && mise run -q "$@"
}
export -f ask
