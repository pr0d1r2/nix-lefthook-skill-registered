#!/usr/bin/env bats

setup() {
    load "${BATS_LIB_PATH}/bats-support/load.bash"
    load "${BATS_LIB_PATH}/bats-assert/load.bash"

    TMP="$BATS_TEST_TMPDIR/repo"
    mkdir -p "$TMP/docs/skills"

    cat > "$TMP/docs/index.md" <<'MD'
@./skills/git.md
@./skills/nix.md
MD

    touch "$TMP/docs/skills/git.md" "$TMP/docs/skills/nix.md"

    export LEFTHOOK_SKILL_REGISTERED_ROOT="$TMP"
    export LEFTHOOK_SKILL_REGISTERED_FILE="docs/index.md"
    export LEFTHOOK_SKILL_REGISTERED_PREFIX="@./skills/"
    export LEFTHOOK_SKILL_REGISTERED_STRIP="docs/skills/"
}

@test "no args exits 0" {
    run lefthook-skill-registered
    assert_success
}

@test "registered file passes" {
    run lefthook-skill-registered "$TMP/docs/skills/git.md"
    assert_success
}

@test "unregistered file fails" {
    touch "$TMP/docs/skills/docker.md"
    run lefthook-skill-registered "$TMP/docs/skills/docker.md"
    assert_failure
    assert_output --partial "not registered"
    assert_output --partial "@./skills/docker.md"
}

@test "file outside skills dir is skipped" {
    touch "$TMP/README.md"
    run lefthook-skill-registered "$TMP/README.md"
    assert_success
}

@test "non-existent file is skipped" {
    run lefthook-skill-registered "$TMP/docs/skills/nonexistent.md"
    assert_success
}

@test "missing registry file exits 0" {
    LEFTHOOK_SKILL_REGISTERED_FILE="nonexistent.md" \
    run lefthook-skill-registered "$TMP/docs/skills/git.md"
    assert_success
}

@test "fails when LEFTHOOK_SKILL_REGISTERED_FILE not set" {
    unset LEFTHOOK_SKILL_REGISTERED_FILE
    run lefthook-skill-registered "$TMP/docs/skills/git.md"
    assert_failure
    assert_output --partial "LEFTHOOK_SKILL_REGISTERED_FILE not set"
}

@test "fails when LEFTHOOK_SKILL_REGISTERED_PREFIX not set" {
    unset LEFTHOOK_SKILL_REGISTERED_PREFIX
    run lefthook-skill-registered "$TMP/docs/skills/git.md"
    assert_failure
    assert_output --partial "LEFTHOOK_SKILL_REGISTERED_PREFIX not set"
}

@test "fails when LEFTHOOK_SKILL_REGISTERED_STRIP not set" {
    unset LEFTHOOK_SKILL_REGISTERED_STRIP
    run lefthook-skill-registered "$TMP/docs/skills/git.md"
    assert_failure
    assert_output --partial "LEFTHOOK_SKILL_REGISTERED_STRIP not set"
}

@test "multiple files: reports all unregistered" {
    touch "$TMP/docs/skills/docker.md" "$TMP/docs/skills/rust.md"
    run lefthook-skill-registered "$TMP/docs/skills/docker.md" "$TMP/docs/skills/rust.md"
    assert_failure
    assert_output --partial "docker.md"
    assert_output --partial "rust.md"
}
