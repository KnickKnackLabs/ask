#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

setup() {
  load test_helper
  install_fake_gum "New question"
}

@test "default menu ignores inherited usage_model" {
  usage_model="openai-codex/gpt-5.5" run ask _default
  [ "$status" -ne 0 ]
  [[ "$output" == *"Missing required flag"* ]]
  [[ "$output" != *"no prompt provided"* ]]
}
