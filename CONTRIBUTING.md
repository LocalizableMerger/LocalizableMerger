# Contribution guide

Thank you for your help with LocalizableMerger.

## Requirements

- macOS 13 or later
- Swift 6.0 or later

## Workflow

1. Fork the repository.
2. Create a branch from `master`.
3. Make the change.
4. Add a test for each change in behavior.
5. Run `swift build`. The build must have no warnings.
6. Run `swift test`.
7. Run `swift run localizable-merger --work-directory Example --check`.
8. Add a line to the `Unreleased` section of `CHANGELOG.md`.
9. Open a pull request.

## Project layout

| Path | Content |
| --- | --- |
| `Sources/LocalizableMergerCore` | All logic. This target does not print and does not exit. |
| `Sources/localizable-merger` | The command-line interface. |
| `Plugins/LocalizableMergerPlugin` | The SwiftPM command plugin. |
| `Tests/LocalizableMergerCoreTests` | The tests. They use Swift Testing and temporary directories. |
| `Example` | A small project. The generated files in this folder must stay current. |

## Rules

- Write code, comments, and documents in English.
- Use short sentences and the active voice in comments and documents.
- Keep the core free of terminal output.
- If a change alters the output format, then regenerate the files in `Example`.

## Bug reports

Open an issue. Include the command, the output, and a small `.strings` file that shows the problem.

## License

The license of each contribution is GPL-3.0. Refer to [LICENSE](LICENSE).
