#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

setup() {
  load test_helper

  # Skip integration tests if pi isn't available
  if ! command -v pi &>/dev/null; then
    skip "pi not installed"
  fi
}

@test "question with direct prompt succeeds" {
  run ask question "Say the word hello and nothing else"
  [ "$status" -eq 0 ]
  echo "$output" | grep -iq "hello"
}

@test "question with piped input as prompt succeeds" {
  run bash -c 'echo "Say the word pineapple and nothing else" | ask question'
  [ "$status" -eq 0 ]
  echo "$output" | grep -iq "pineapple"
}

@test "question with file context succeeds" {
  echo "The answer is 42." > "$BATS_TEST_TMPDIR/data.txt"
  run ask question -f "$BATS_TEST_TMPDIR/data.txt" "What is the answer?"
  [ "$status" -eq 0 ]
  [[ "$output" == *"42"* ]]
}

@test "question with missing file fails" {
  run ask question -f "/nonexistent/file.txt" "hello"
  [ "$status" -ne 0 ]
  [[ "$output" == *"file not found"* ]]
}

@test "question with no prompt and no stdin fails" {
  run ask question
  [ "$status" -ne 0 ]
  [[ "$output" == *"no prompt"* ]]
}
