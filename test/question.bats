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

@test "question --continue scrubs inherited usage vars before sessions list" {
  DISPATCH_CONTEXT="review PR 123" usage_filter="session.meta.tool=parent" run ask question -m openai-codex/gpt-5.5 --continue "hello again"
  [ "$status" -eq 0 ]
  grep -q '^list-dispatch-context=$' "$ASK_SESSIONS_LOG"
  grep -q '^list-usage-filter=$' "$ASK_SESSIONS_LOG"
  grep -q '^wake last-ask-session ' "$ASK_SESSIONS_LOG"
}

@test "question treats --continue after -- as prompt text" {
  run ask question -m openai-codex/gpt-5.5 -- --continue
  [ "$status" -eq 0 ]
  grep -q '^new ask-' "$ASK_SESSIONS_LOG"
  grep -q '^wake new-session-id --message --continue --model openai-codex/gpt-5.5$' "$ASK_SESSIONS_LOG"
  ! grep -q '^list --filter session.meta.tool=ask --limit 1 --json$' "$ASK_SESSIONS_LOG"
  ! grep -q '^wake last-ask-session ' "$ASK_SESSIONS_LOG"
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

@test "question applies explicitly passed provider to unqualified model" {
  run ask question --provider openai-codex -m gpt-5.5 "hello"
  [ "$status" -eq 0 ]
  grep -q '^wake new-session-id --message hello --model openai-codex/gpt-5.5$' "$ASK_SESSIONS_LOG"
}

@test "question ignores inherited usage_provider" {
  usage_provider="openai-codex" run ask question -m gpt-5.5 "hello"
  [ "$status" -ne 0 ]
  [[ "$output" == *"provider-qualified"* ]]
}

@test "question ignores inherited usage_prompt" {
  usage_prompt="parent prompt" run ask question -m openai-codex/gpt-5.5
  [ "$status" -ne 0 ]
  [[ "$output" == *"no prompt"* ]]
}

@test "question ignores inherited optional context and verbose flags" {
  echo "parent secret" > "$BATS_TEST_TMPDIR/parent.txt"
  usage_file="$BATS_TEST_TMPDIR/parent.txt" usage_clipboard="true" usage_verbose="true" run ask question -m openai-codex/gpt-5.5 "hello"
  [ "$status" -eq 0 ]
  [[ "$output" == "hello" ]]
  grep -q '^wake new-session-id --message hello --model openai-codex/gpt-5.5$' "$ASK_SESSIONS_LOG"
  ! grep -q 'parent secret' "$ASK_SESSIONS_LOG"
}

@test "question required model ignores inherited usage_model" {
  usage_model="openai-codex/gpt-5.5" run ask question "hello"
  [ "$status" -ne 0 ]
  [[ "$output" == *"Missing required flag"* ]]
}

@test "question uses ask identity and scrubs dispatch context" {
  AGENT_IDENTITY="You are x1f9." DISPATCH_CONTEXT="review PR 123" run ask question -m openai-codex/gpt-5.5 "hello"
  [ "$status" -eq 0 ]
  grep -q '^wake-agent-identity=You are ask, a concise question-answering assistant\.$' "$ASK_SESSIONS_LOG"
  grep -q '^wake-dispatch-context=$' "$ASK_SESSIONS_LOG"
  ! grep -q 'x1f9' "$ASK_SESSIONS_LOG"
  ! grep -q 'review PR 123' "$ASK_SESSIONS_LOG"
}

@test "question scrubs inherited usage vars before sessions commands" {
  DISPATCH_CONTEXT="review PR 123" usage_background="true" usage_headless="true" usage_context="parent context" usage_harness="claude" run ask question -m openai-codex/gpt-5.5 "hello"
  [ "$status" -eq 0 ]
  grep -q '^new-dispatch-context=$' "$ASK_SESSIONS_LOG"
  grep -q '^new-usage-context=$' "$ASK_SESSIONS_LOG"
  grep -q '^new-usage-harness=$' "$ASK_SESSIONS_LOG"
  grep -q '^wake-dispatch-context=$' "$ASK_SESSIONS_LOG"
  grep -q '^wake-usage-background=$' "$ASK_SESSIONS_LOG"
  grep -q '^wake-usage-headless=$' "$ASK_SESSIONS_LOG"
  grep -q '^wake-usage-context=$' "$ASK_SESSIONS_LOG"
}
