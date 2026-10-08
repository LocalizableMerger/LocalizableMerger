# Changelog

This file records all notable changes to this project.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
This project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.0.0] - 2026-10-07

### Added

- `LocalizableMergerCore` library product that contains all merge logic.
- `LocalizableMergerPlugin` SwiftPM command plugin with the verb `merge-localizables`.
- `--dry-run` flag that shows the result and writes no files.
- `--check` flag that exits with code 1 when a generated file is absent or stale.
- `--strict` flag that treats orphan keys as errors.
- `--quiet` flag and `--version` flag.
- `exclude` and `generatedSuffix` keys in `LocalizableMerger.yml`.
- Warnings for orphan keys. An orphan key is in a target file but not in the base file.
- Warnings for duplicate keys in one file.
- Report of target files that have no base file.
- Own `.strings` parser with file and line in each syntax error.
- Test suite with Swift Testing.
- CI workflow, Dependabot configuration, `.editorconfig`, and `CONTRIBUTING.md`.

### Changed

- The package requires Swift 6.0 and macOS 13.
- The package name is `LocalizableMerger`. The executable name stays `localizable-merger`.
- The options use kebab-case: `--base-folder`, `--work-directory`, `--config-file`.
- The tool pairs a target file with a base file by language and by table name.
- The tool writes a generated file only when the content is different.
- The header of a generated file has new text.
- swift-argument-parser replaces Guaka. Yams replaces YamlSwift.
- An absent base folder is an error. The exit code is 1.
- A configuration file that the user passes with `--config-file` must exist.

### Fixed

- The writer escapes `\`, line breaks, and tabs. Version 1.x escaped only `"`.
- The base folder match uses full path components. Version 1.x used a substring match.
- `InfoPlist.strings` does not merge with `Localizable.strings`.
- Paths that contain spaces work.
- The tool ignores `.build`, `Pods`, `Carthage`, `DerivedData`, `node_modules`, and hidden directories.

### Removed

- Guaka and YamlSwift dependencies.
- XCTest manifests for Linux.
- The `.swiftpm` directory from version control.

[Unreleased]: https://github.com/LocalizableMerger/LocalizableMerger/compare/2.0.0...HEAD
[2.0.0]: https://github.com/LocalizableMerger/LocalizableMerger/releases/tag/2.0.0
