#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

setup() {
  load test_helper
  install_fake_sessions
}

@test "question with direct prompt succeeds" {
  run ask question -m openai-codex/gpt-5.5 "Say the word hello and nothing else"
  [ "$status" -eq 0 ]
  echo "$output" | grep -iq "hello"
}

@test "question with piped input as prompt succeeds" {
  run bash -c 'echo "Say the word pineapple and nothing else" | ask question -m openai-codex/gpt-5.5'
  [ "$status" -eq 0 ]
  echo "$output" | grep -iq "pineapple"
}

@test "question with file context succeeds" {
  echo "The answer is 42." > "$BATS_TEST_TMPDIR/data.txt"
  run ask question -m openai-codex/gpt-5.5 -f "$BATS_TEST_TMPDIR/data.txt" "What is the answer?"
  [ "$status" -eq 0 ]
  [[ "$output" == *"42"* ]]
}

@test "question with missing file fails" {
  run ask question -m openai-codex/gpt-5.5 -f "/nonexistent/file.txt" "hello"
  [ "$status" -ne 0 ]
  [[ "$output" == *"file not found"* ]]
}

@test "question with no prompt and no stdin fails" {
  run ask question -m openai-codex/gpt-5.5
  [ "$status" -ne 0 ]
  [[ "$output" == *"no prompt"* ]]
}

@test "question without model fails clearly" {
  run ask question "hello"
  [ "$status" -ne 0 ]
  [[ "$output" == *"Missing required flag"* ]]
}

@test "question creates a fresh session by default" {
  run ask question -m openai-codex/gpt-5.5 "hello"
  [ "$status" -eq 0 ]
  grep -q '^new ask-' "$ASK_SESSIONS_LOG"
  grep -q '^wake new-session-id ' "$ASK_SESSIONS_LOG"
}

@test "question --continue resumes latest ask session" {
  run ask question -m openai-codex/gpt-5.5 --continue "hello again"
  [ "$status" -eq 0 ]
  grep -q '^list --filter session.meta.tool=ask --limit 1 --json$' "$ASK_SESSIONS_LOG"
  grep -q '^wake last-ask-session ' "$ASK_SESSIONS_LOG"
  ! grep -q '^new ' "$ASK_SESSIONS_LOG"
}

@test "question ignores inherited usage_session by not exposing --session" {
  usage_session="parent-session" run ask question -m openai-codex/gpt-5.5 "hello"
  [ "$status" -eq 0 ]
  grep -q '^new ask-' "$ASK_SESSIONS_LOG"
  grep -q '^wake new-session-id ' "$ASK_SESSIONS_LOG"
  ! grep -q '^wake parent-session ' "$ASK_SESSIONS_LOG"
}

@test "question ignores inherited usage_continue" {
  usage_continue="true" run ask question -m openai-codex/gpt-5.5 "hello"
  [ "$status" -eq 0 ]
  grep -q '^new ask-' "$ASK_SESSIONS_LOG"
  grep -q '^wake new-session-id ' "$ASK_SESSIONS_LOG"
  ! grep -q '^list --filter session.meta.tool=ask --limit 1 --json$' "$ASK_SESSIONS_LOG"
  ! grep -q '^wake last-ask-session ' "$ASK_SESSIONS_LOG"
}

@test "question required model ignores inherited usage_model" {
  usage_model="openai-codex/gpt-5.5" run ask question "hello"
  [ "$status" -ne 0 ]
  [[ "$output" == *"Missing required flag"* ]]
}
