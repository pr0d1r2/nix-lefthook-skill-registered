# shellcheck shell=bash
# Lefthook-compatible file-registry check.
# Verifies that files matching a directory pattern have a corresponding
# import/reference line in a registry file.
#
# Example: ensure every docs/skills/*.md is listed in docs/index.md
# as `@./skills/<path>`.
#
# Usage: lefthook-skill-registered file1.md [file2.md ...]
# NOTE: sourced by writeShellApplication — no shebang or set needed.

ROOT="${LEFTHOOK_SKILL_REGISTERED_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
REGISTRY="${LEFTHOOK_SKILL_REGISTERED_FILE:-}"
PREFIX="${LEFTHOOK_SKILL_REGISTERED_PREFIX:-}"
STRIP="${LEFTHOOK_SKILL_REGISTERED_STRIP:-}"

if [ -z "$REGISTRY" ]; then
  echo "check-skill-registered: LEFTHOOK_SKILL_REGISTERED_FILE not set" >&2
  echo "  Set it to the registry file path (relative to repo root)." >&2
  exit 1
fi

if [ -z "$PREFIX" ]; then
  echo "check-skill-registered: LEFTHOOK_SKILL_REGISTERED_PREFIX not set" >&2
  echo "  Set it to the expected import prefix, e.g. '@./skills/'." >&2
  exit 1
fi

if [ -z "$STRIP" ]; then
  echo "check-skill-registered: LEFTHOOK_SKILL_REGISTERED_STRIP not set" >&2
  echo "  Set it to the directory prefix to strip from file paths" >&2
  echo "  before appending to PREFIX, e.g. 'docs/skills/'." >&2
  exit 1
fi

REGISTRY_PATH="$ROOT/$REGISTRY"
[ -f "$REGISTRY_PATH" ] || exit 0

failed=0
for file in "$@"; do
  [ -f "$file" ] || continue

  abs="$file"
  case "$file" in
    /*) : ;;
    *) abs="$ROOT/$file" ;;
  esac

  rel="${abs#"$ROOT/"}"

  case "$rel" in
    "${STRIP}"*) : ;;
    *) continue ;;
  esac

  subpath="${rel#"$STRIP"}"
  import_line="${PREFIX}${subpath}"

  if ! grep -Fxq "$import_line" "$REGISTRY_PATH"; then
    printf '%s: not registered — add this line to %s:\n    %s\n' \
      "$rel" "$REGISTRY" "$import_line" >&2
    failed=1
  fi
done

exit "$failed"
