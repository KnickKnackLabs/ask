#!/usr/bin/env bash

if [ -z "${REPO_DIR:-}" ]; then
  REPO_DIR="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
fi

# Source libs for unit testing
source "$REPO_DIR/lib/sessions.sh"
source "$REPO_DIR/lib/clipboard.sh"

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
    printf 'new-dispatch-context=%s\n' "${DISPATCH_CONTEXT:-}" >> "${ASK_SESSIONS_LOG:?}"
    printf 'new-usage-context=%s\n' "${usage_context:-}" >> "${ASK_SESSIONS_LOG:?}"
    printf 'new-usage-harness=%s\n' "${usage_harness:-}" >> "${ASK_SESSIONS_LOG:?}"
    echo "new-session-id"
    ;;
  list)
    printf 'list-dispatch-context=%s\n' "${DISPATCH_CONTEXT:-}" >> "${ASK_SESSIONS_LOG:?}"
    printf 'list-usage-filter=%s\n' "${usage_filter:-}" >> "${ASK_SESSIONS_LOG:?}"
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

install_fake_gum() {
  local bin_dir="$BATS_TEST_TMPDIR/bin"
  mkdir -p "$bin_dir"
  export PATH="$bin_dir:$PATH"
  export ASK_FAKE_GUM_CHOICE="${1:-New question}"

  cat > "$bin_dir/gum" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
  choose)
    printf '%s\n' "${ASK_FAKE_GUM_CHOICE:?}"
    ;;
  file)
    printf '%s\n' "${ASK_FAKE_GUM_FILE:-}"
    ;;
  *)
    echo "unexpected gum command: $*" >&2
    exit 1
    ;;
esac
SH
  chmod +x "$bin_dir/gum"
}

# Wrapper to run ask tasks through mise
ask() {
  cd "$REPO_DIR" && mise run -q "$@"
}
export -f ask
