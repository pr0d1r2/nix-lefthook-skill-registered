# SPEC — nix-lefthook-skill-registered

## §G Goal

Lefthook-compatible file-registry enforcer. Verify every file under a
configured directory is *registered* — referenced by an expected import line
in a parent index/manifest file. Useful for guaranteeing new docs pages,
skill files, or module definitions are always wired into a central manifest.
Nix flake pkg. Opensource-safe: zero credentials, zero local paths, zero
private refs.

## §C Constraints

- C1: Pure bash — no Python/Ruby/etc runtime deps; only `git` + coreutils
- C2: Nix flake — `writeShellApplication` pkg, plain `mkShell` devShells with
  inlined sibling lefthook wrappers (no `nix-dev-shell-agentic` input)
- C3: MIT license
- C4: Multi-platform: `aarch64-darwin`, `x86_64-darwin`, `x86_64-linux`,
  `aarch64-linux`
- C5: Detached from parent project — no credential leaks, no hardcoded local
  paths, no private repo refs
- C6: All config via env vars — no config files beyond baseline lint configs
- C7: Exit non-zero when a scoped file is unregistered — hard enforcement,
  blocks commit
- C8: Flattened dependency closure — `flake = false` `-src` inputs +
  `nixpkgs-lock`, no transitive flake dep-tree explosion

## §I Interfaces

- I.cli: `lefthook-skill-registered file1 [file2 ...]` — main binary; exit 1
  if any scoped argument is unregistered (blocks commit), exit 0 otherwise
- I.env: `LEFTHOOK_SKILL_REGISTERED_FILE` (required — registry path relative
  to repo root), `LEFTHOOK_SKILL_REGISTERED_PREFIX` (required — expected
  import-line prefix, e.g. `@./skills/`), `LEFTHOOK_SKILL_REGISTERED_STRIP`
  (required — dir prefix stripped from each path before appending to PREFIX,
  e.g. `docs/skills/`), `LEFTHOOK_SKILL_REGISTERED_ROOT` (default
  `git rev-parse --show-toplevel`, else `pwd` — override repo root for
  testing), `LEFTHOOK_SKILL_REGISTERED_TIMEOUT` (default `30`, seconds —
  wraps the binary in `timeout` from the hook configs)
- I.remote: `lefthook-remote.yml` — consumers add as a lefthook remote;
  defines `pre-commit` (`{staged_files}`) + `pre-push` (`{push_files}`)
  commands. Consumers **must** add a `glob` to scope which files trigger it
- I.flake: `packages.${system}.default` — Nix pkg output
  (`lefthook-skill-registered`)
- I.devshell: `devShells.${system}.default` + `.#ci` — dev/CI shells, both
  bundling the package, bats-with-libs, and 15 inlined lefthook wrappers
- I.ci: `.github/workflows/ci.yml` — linux + macos via
  `nix-lefthook-ci-action`; `.github/workflows/update-pins.yml` — daily
  `nixpkgs-lock` pin bump PR

## §V Invariants

- V1: Each argument resolved to an absolute path, made relative to `ROOT`; if
  it does not start with `STRIP` it is *skipped* (out of scope) — exit 0 for
  that file
- V2: For an in-scope file, the expected import line is
  `PREFIX + (rel path with STRIP prefix removed)`; pass iff that exact line
  exists in the registry (`grep -Fxq`, full-line literal match)
- V3: An unregistered in-scope file prints `<rel>: not registered` plus the
  exact line to add, and sets exit 1 — hard requirement, blocks commit
- V4: All in-scope files are checked; every unregistered one is reported (no
  short-circuit) before the non-zero exit
- V5: Missing registry file (`REGISTRY_PATH` absent) → silent exit 0 (no
  crash before the registry exists)
- V6: A path argument that is not an existing file is skipped (no crash on
  deleted/renamed paths)
- V7: Unset `LEFTHOOK_SKILL_REGISTERED_FILE` → exit 1 with a usage message —
  required config is hard-enforced
- V8: Unset `LEFTHOOK_SKILL_REGISTERED_PREFIX` → exit 1 with a usage message
- V9: Unset `LEFTHOOK_SKILL_REGISTERED_STRIP` → exit 1 with a usage message
- V10: No args → exit 0 (the loop body runs zero times)
- V11: No credentials, secrets, tokens, API keys, or private paths in any
  tracked file
- V12: No hardcoded local filesystem paths (enforced by
  `nix-lefthook-git-no-local-paths` hook)
- V13: `dev.sh` sets `BATS_LIB_PATH` (via `@BATS_LIB_PATH@` substitution in
  the default devShell `shellHook`) and auto-installs lefthook when the
  `.git/hooks/pre-commit` hook is missing
- V14: CI runs `nix-lefthook-ci-action` (build + lefthook pre-commit +
  pre-push) on linux + macos
- V15: All linters pass via lefthook remotes: nixfmt, shellcheck, shfmt,
  statix, deadnix, yamllint, typos, trailing-whitespace,
  missing-final-newline, git-conflict-markers, editorconfig-checker,
  git-no-local-paths, nix-flake-check, nix-no-embedded-shell, file-size-check
- V16: `flake.lock` contains only `nixpkgs-lock` + the 14 `flake = false`
  `-src` leaves — flattened, no transitive flake explosion (C8)
- V17: `config/lefthook/file_size_limits.yml` caps file sizes (`nix` 10240 to
  admit the inlined-wrapper `flake.nix`; `lock` 65536; default 4096)

## §T Tasks

| id | status | task | cites |
| ---- | -------- | ---- | ------- |
| T1 | x | core registry script: ROOT/REGISTRY/PREFIX/STRIP resolution, scope filter, exact-line lookup, exit 1 on gaps | V1,V2,V3,V4,I.cli |
| T2 | x | required-env enforcement: FILE, PREFIX, STRIP each hard-fail when unset | V7,V8,V9,I.env |
| T3 | x | graceful skips: missing registry, non-file args, no args | V5,V6,V10 |
| T4 | x | Nix flake pkg (`writeShellApplication`, runtimeInputs git) | C1,C2,I.flake |
| T5 | x | flattened flake: drop nix-dev-shell-agentic, add 14 flake=false -src inputs, plain mkShell ci+default | C2,C8,V16,I.devshell |
| T6 | x | lefthookWrappersFor helper — 15 inlined wrappers incl. nested file-size-check + nix-no-embedded-shell SCANNER | V15,I.devshell |
| T7 | x | lefthook-remote.yml for consumers (pre-commit + pre-push) | I.remote |
| T8 | x | dev.sh — BATS_LIB_PATH + auto-install lefthook | V13 |
| T9 | x | unit tests: lefthook-skill-registered.bats (11 tests, assert_failure for gaps) | V1-V10 |
| T10 | x | GitHub Actions CI: linux + macos via nix-lefthook-ci-action | V14,I.ci |
| T11 | x | update-pins.yml: daily nixpkgs-lock pin-bump PR | I.ci |
| T12 | x | linter suite via 15 lefthook remotes in lefthook.yml | V15 |
| T13 | x | file_size_limits.yml: nix 10240 to admit flattened flake.nix | V17 |
| T14 | x | opensource audit: no credentials/local-paths/private-refs in git history | V11,V12,C5 |
| T15 | x | .gitignore: result, result-*, .direnv | C5 |
