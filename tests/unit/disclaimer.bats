#!/usr/bin/env bats

@test "disclaimer names the hook definition that exists" {
    run grep -F 'This repository is gated by `lefthook-remote.yml`.' \
        "$BATS_TEST_DIRNAME/../../docs/LLM-DISCLAIMER.md"
    [ "$status" -eq 0 ]
}
