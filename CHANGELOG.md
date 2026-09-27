# Changelog

All notable changes to this project are documented here.

## Unreleased

- Fixed: `packages.default` restored (lost in the referenced migration);
  bats specs run the working-tree script instead of a binary the dev shell
  never provided.
- Fixed: `.editorconfig` sets `switch_case_indent` for `*.sh`, matching the
  indented `case` arms the standard's shfmt check now reads it for.
- Changed: flake pins refreshed.
