# nix-lefthook-skill-registered

<!-- hallucinogen:autonomy-disclaimer start -->
> Read [LLM-DISCLAIMER](docs/LLM-DISCLAIMER.md) first. This repository is
> tended by an autonomous loop, and that file says what the loop may do here,
> what it may not, and what to check before trusting anything in this tree.
<!-- hallucinogen:autonomy-disclaimer end -->

[![CI](https://github.com/pr0d1r2/nix-lefthook-skill-registered/actions/workflows/ci.yml/badge.svg)](https://github.com/pr0d1r2/nix-lefthook-skill-registered/actions/workflows/ci.yml) [![NixOS 26.05](https://img.shields.io/badge/NixOS-26.05-blue.svg?logo=nixos)](https://nixos.org)

> This code is LLM-generated and validated through an automated integration
> process using [lefthook](https://github.com/evilmartians/lefthook) git hooks,
> [bats](https://github.com/bats-core/bats-core) unit tests, and GitHub Actions CI.

Lefthook-compatible file-registry check, packaged as a Nix flake.

Verifies that files under a directory are registered (referenced) in a parent
index file. Useful for enforcing that new documentation pages, skill files, or
module definitions are always wired into a central manifest.

## Example

Given this structure:

```text
docs/skills/git.md
docs/skills/nix.md
docs/index.md        # must contain @./skills/git.md and @./skills/nix.md
```

Configure:

```bash
export LEFTHOOK_SKILL_REGISTERED_FILE=docs/index.md
export LEFTHOOK_SKILL_REGISTERED_PREFIX='@./skills/'
export LEFTHOOK_SKILL_REGISTERED_STRIP='docs/skills/'
```

Adding `docs/skills/docker.md` without a matching `@./skills/docker.md` line
in `docs/index.md` will fail the hook.

## Architecture

```mermaid
flowchart LR
  consumer["consumer lefthook.yml"] -->|"remotes"| remote["lefthook-remote.yml"]
  remote -->|"pre-commit → {staged_files}"| lefthook_skill_registered["lefthook-skill-registered"]
  remote -->|"pre-push → {push_files}"| lefthook_skill_registered["lefthook-skill-registered"]
  lefthook_skill_registered -->|"exit status"| consumer
```

## Usage

### Option A: Lefthook remote (recommended)

```yaml
remotes:
  - git_url: https://github.com/pr0d1r2/nix-lefthook-skill-registered
    ref: main
    configs:
      - lefthook-remote.yml
```

You **must** also set a `glob` in your local config to scope which files
trigger the check:

```yaml
pre-commit:
  commands:
    skill-registered:
      glob: "docs/skills/**/*.md"
      run: timeout 30 lefthook-skill-registered {staged_files}
```

### Option B: Flake input

```nix
inputs.nix-lefthook-skill-registered = {
  url = "github:pr0d1r2/nix-lefthook-skill-registered";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

### Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `LEFTHOOK_SKILL_REGISTERED_TIMEOUT` | `30` | Timeout in seconds |
| `LEFTHOOK_SKILL_REGISTERED_FILE` | *(required)* | Registry file path (relative to repo root) |
| `LEFTHOOK_SKILL_REGISTERED_PREFIX` | *(required)* | Expected import line prefix |
| `LEFTHOOK_SKILL_REGISTERED_STRIP` | *(required)* | Directory prefix to strip from file paths |
| `LEFTHOOK_SKILL_REGISTERED_ROOT` | git root | Override repo root (for testing) |

## Development architecture

```mermaid
flowchart LR
  envrc[".envrc"] -->|"use flake"| flake["flake.nix"]
  flake -->|"mkConsumerFlake"| sas["set-and-setting"]
  flake -->|"devShell"| shell["dev shell"]
  shell -->|"on entry"| devsh["dev.sh"]
  sas -->|"assembled hooks"| lh["lefthook.yml"]
  lh -->|"pre-commit / pre-push"| checks["linters, bats, nix flake check"]
  ci[".github/workflows/ci.yml"] -->|"guardrails.yml"| checks
```

## License

MIT
