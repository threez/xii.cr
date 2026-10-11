# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.2] - 2026-10-11

### Changed

- Bumped the `ameba` dev dependency from `~> 1.6.0` to `~> 1.7.0` and updated
  the `Makefile` to explicitly build `ameba` via `shards build` after
  `shards install`, since ameba 1.7.0 no longer builds its own executable as
  part of `shards install`.
- Restructured `.github/workflows/ci.yml` into separate `lint` (format check,
  ameba lint, compile check) and `test` (specs and examples across Linux and
  macOS) jobs, pinned to Crystal 1.20.2, and added shards caching.
- Pinned the Crystal version used in `.github/workflows/pages.yml` to 1.20.2
  for consistency with CI.

### Fixed

- Adjusted macro expression spacing and spec boolean-literal comparisons in
  `src/xii/configurable.cr` and specs to satisfy new ameba 1.7.0 lint rules
  (`Lint/WhitespaceAroundMacroExpression`, `Lint/SpecEqWithBoolOrNilLiteral`).
- Converted a `%()` percent-string literal to a heredoc in
  `examples/03_json_file.cr` to satisfy ameba's `Style/MultilineStringLiteral`
  rule.
