# Flatten SPEC — nix-lefthook-skill-registered

## Goal
Remove the `nix-dev-shell-agentic` flake input (and its transitive
explosion) from `flake.nix`, preserving the `lefthook-skill-registered`
package output and keeping CI (`nix develop .#ci` + remote lefthook hooks)
and bats green.

## Before
- flake.lock: 59 nodes.
- Inputs: nixpkgs-lock, nixpkgs(follows), nix-dev-shell-agentic(flake).
- Outputs: packages.<sys>.default = lefthook-skill-registered; devShells
  ci/default via nix-dev-shell-agentic.lib.mkShells.

## Consumption of the agentic devShell here
- `.envrc` = `use flake` → devShells.<sys>.default.
- CI (nix-lefthook-ci-action, default devshell=ci) enters
  `nix develop .#ci --ignore-environment` and runs lefthook install /
  pre-commit / pre-push --all-files.
- lefthook.yml `remotes:` invoke wrapper binaries that must be on PATH in
  the ci shell: lefthook-{nixfmt,shellcheck,shfmt,statix,deadnix,yamllint,
  typos,trailing-whitespace,missing-final-newline,git-conflict-markers,
  editorconfig-checker,git-no-local-paths,nix-no-embedded-shell,
  file-size-check} (+ get-file-size-limit sub-wrapper); bare `nix flake
  check` (nix-flake-check); plus lefthook, git, coreutils, parallel.
- bats unit tests need BATS_LIB_PATH + lefthook-skill-registered on PATH.

## Changes
### Inputs
Remove nix-dev-shell-agentic. Add `flake = false` `-src` inputs for each
sibling wrapper the remotes invoke (14 leaves). Result inputs: nixpkgs-lock,
nixpkgs(follows), + 14 flake=false leaves. No flake input → no dep-tree
explosion.

### packages (UNCHANGED logic)
packages.<sys>.default = writeShellApplication { name="lefthook-skill-registered";
runtimeInputs=with pkgs; [ git ]; text=readFile ./lefthook-skill-registered.sh; }.

### devShells (plain mkShell)
lefthookWrappersFor helper (mirrors proven statix template:
file-size-check gets nested get-file-size-limit handling,
nix-no-embedded-shell gets SCANNER prefix, rest via `wrap`).
batsWithLibsFor helper. ciCommon = [self pkg, batsWithLibs, bats, coreutils,
git, lefthook, nix, parallel] ++ wrappers.
- ci = mkShell { packages = ciCommon; BATS_LIB_PATH = "${batsWithLibs}/share/bats"; }
- default = mkShell { packages = ciCommon; shellHook = dev.sh expanded; }

### Side changes required to land a flattened flake green
1. config/lefthook/file_size_limits.yml: nix 4096 → 10240. The flattened
  flake.nix grows (14 inline wrappers); mirrors the proven template repos.
  Pure config, no logic.
2. shfmt -i2 -ci reformat of any shell touched if needed.

## Validation gate (all must pass)
1. nix flake check — PASS.
2. nix flake show — packages.<sys>.default = lefthook-skill-registered;
  devShells ci+default. UNCHANGED set.
3. bats tests/unit/ inside nix develop .#ci — PASS.
4. lefthook run pre-commit --all-files inside .#ci — PASS.
5. lock nodes << 59.

## Then
Branch flatten-drop-agentic, commit, push, DRAFT PR.
Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
