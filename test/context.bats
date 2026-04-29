#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

setup() {
  export ASK_DIR="$BATS_TEST_TMPDIR/ask"
  export HISTORY_FILE="$ASK_DIR/history.jsonl"
  load test_helper
  install_fake_sessions
}

# ── build_prompt ─────────────────────────────────────────────

@test "build_prompt with no context returns bare prompt" {
  result=$(build_prompt "hello")
  [ "$result" = "hello" ]
}

@test "build_prompt with context wraps in XML tags" {
  result=$(build_prompt "summarize" "some content")
  [[ "$result" == *"<context>"* ]]
  [[ "$result" == *"some content"* ]]
  [[ "$result" == *"</context>"* ]]
  [[ "$result" == *"summarize"* ]]
}

@test "build_prompt puts context before prompt" {
  result=$(build_prompt "question" "data")
  context_pos=$(echo "$result" | grep -n "context" | head -1 | cut -d: -f1)
  question_pos=$(echo "$result" | grep -n "question" | head -1 | cut -d: -f1)
  [ "$context_pos" -lt "$question_pos" ]
}

# ── save_history ─────────────────────────────────────────────

@test "save_history appends to history file" {
  save_history "test prompt"
  [ -f "$HISTORY_FILE" ]
  
  line=$(cat "$HISTORY_FILE")
  [[ "$line" == *"test prompt"* ]]
  [[ "$line" == *"timestamp"* ]]
}

@test "save_history appends multiple entries" {
  save_history "first"
  save_history "second"
  
  count=$(wc -l < "$HISTORY_FILE")
  [ "$count" -eq 2 ]
}
