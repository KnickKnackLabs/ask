#!/usr/bin/env bash

if [ -z "${MISE_CONFIG_ROOT:-}" ]; then
  echo "MISE_CONFIG_ROOT not set — run tests via: mise run test" >&2
  exit 1
fi

# Source libs for unit testing
source "$MISE_CONFIG_ROOT/lib/pi.sh"
source "$MISE_CONFIG_ROOT/lib/clipboard.sh"

# Wrapper to run ask tasks through mise
ask() {
  cd "$MISE_CONFIG_ROOT" && mise run -q "$@"
}
export -f ask
