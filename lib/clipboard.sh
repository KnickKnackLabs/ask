#!/usr/bin/env bash
#
# clipboard.sh — Clipboard operations
#

get_clipboard() {
  if command -v pbpaste &>/dev/null; then
    pbpaste
  elif command -v xclip &>/dev/null; then
    xclip -selection clipboard -o
  elif command -v xsel &>/dev/null; then
    xsel --clipboard --output
  else
    echo "error: no clipboard command found (pbpaste, xclip, or xsel)" >&2
    return 1
  fi
}
