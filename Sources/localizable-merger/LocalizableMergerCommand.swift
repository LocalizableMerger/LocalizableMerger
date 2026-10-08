import ArgumentParser
import Foundation
import LocalizableMergerCore

@main
struct LocalizableMergerCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "localizable-merger",
        abstract: "Merge base .strings files into target .strings files.",
        discussion: """
            The tool finds each .strings file in a <language>.lproj folder. \
            For each file outside the base folder, the tool writes <Name>_generated.strings. \
            The generated file contains the base keys and the keys of the target file.
            """,
        version: LocalizableMerger.version
    )

    @Option(name: .customLong("base-folder"), help: "The folder that contains the base .strings files.")
    var baseFolder: String?

    @Option(name: .customLong("work-directory"), help: "The root of the project. (default: the current directory)")
    var workDirectory: String?

    @Option(
        name: .customLong("config-file"),
        help: "The path of the configuration file. (default: \(Configuration.defaultFileName))"
    )
    var configFile: String?

    // The 1.x spellings stay valid.
    @Option(name: .customLong("baseFolder"), help: .hidden)
    var legacyBaseFolder: String?

    @Option(name: .customLong("workDirectory"), help: .hidden)
    var legacyWorkDirectory: String?

    @Option(name: .customLong("configFile"), help: .hidden)
    var legacyConfigFile: String?

    @Flag(name: .customLong("dry-run"), help: "Show the result and write no files.")
    var dryRun = false

    @Flag(help: "Write no files. Exit with code 1 when a generated file is absent or stale.")
    var check = false

    @Flag(help: "Treat keys that are not in the base file as errors.")
    var strict = false

    @Flag(help: "Print warnings and errors only.")
    var quiet = false

    func run() throws {
        let currentDirectory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
        let root = URL(
            fileURLWithPath: workDirectory ?? legacyWorkDirectory ?? ".",
            isDirectory: true,
            relativeTo: currentDirectory
        )
        let configuration = try Configuration.load(
            workDirectory: root,
            configFile: configFile ?? legacyConfigFile,
            baseFolder: baseFolder ?? legacyBaseFolder
        )
        let writes = !(dryRun || check)
        let report = try Merger.run(workDirectory: root, configuration: configuration, write: writes)

        let console = Console()
        if !quiet {
            for output in report.outputs {
                console.printStatus(label(for: output.status, writes: writes), output.status == .unchanged ? .dim : .green,
                                    "\(report.relativePath(output.output)) (\(output.keyCount) keys)")
            }
            for file in report.missingBase {
                console.printStatus("skipped", .yellow,
                                    "\(report.relativePath(file.url)) (no base file for \(file.language)/\(file.table))")
            }
        }
        for warning in report.duplicateKeys {
            console.warn("\(report.relativePath(warning.file)): duplicate keys, the last value wins: \(warning.keys.joined(separator: ", "))")
        }
        for warning in report.orphanKeys {
            let message = "\(report.relativePath(warning.file)): keys that are not in the base file: \(warning.keys.joined(separator: ", "))"
            if strict { console.error(message) } else { console.warn(message) }
        }
        if !quiet {
            let warnings = report.duplicateKeys.count + report.orphanKeys.count
            print("\(report.changed.count) \(writes ? "generated" : "to generate"), \(report.unchanged.count) unchanged, "
                + "\(report.missingBase.count) skipped, \(warnings) \(warnings == 1 ? "warning" : "warnings").")
        }

        var failed = false
        if check, !report.isUpToDate {
            console.error("Generated files that are absent or stale: \(report.changed.count). Run localizable-merger to update them.")
            failed = true
        }
        if strict, !report.orphanKeys.isEmpty {
            console.error("Strict mode. Target files with keys that are not in the base file: \(report.orphanKeys.count).")
            failed = true
        }
        if failed { throw ExitCode.failure }
    }

    private func label(for status: MergeReport.Status, writes: Bool) -> String {
        switch (status, writes) {
        case (.unchanged, _): "unchanged"
        case (.created, true): "created"
        case (.updated, true): "updated"
        case (.created, false): check ? "absent" : "to create"
        case (.updated, false): check ? "stale" : "to update"
        }
    }
}

/// Terminal output. Colors are on when the stream is a terminal and `NO_COLOR` is not set.
struct Console {
    enum Color: String {
        case red = "31", green = "32", yellow = "33", dim = "2"
    }

    private let colorOut = Console.supportsColor(STDOUT_FILENO)
    private let colorError = Console.supportsColor(STDERR_FILENO)

    private static func supportsColor(_ descriptor: Int32) -> Bool {
        isatty(descriptor) == 1 && (ProcessInfo.processInfo.environment["NO_COLOR"] ?? "").isEmpty
    }

    private func paint(_ text: String, _ color: Color, enabled: Bool) -> String {
        enabled ? "\u{1B}[\(color.rawValue)m\(text)\u{1B}[0m" : text
    }

    func printStatus(_ label: String, _ color: Color, _ message: String) {
        let padded = label.padding(toLength: 12, withPad: " ", startingAt: 0)
        print(paint(padded, color, enabled: colorOut) + " " + message)
    }

    func warn(_ message: String) {
        printError(paint("warning:", .yellow, enabled: colorError) + " " + message)
    }

    func error(_ message: String) {
        printError(paint("error:", .red, enabled: colorError) + " " + message)
    }

    private func printError(_ line: String) {
        FileHandle.standardError.write(Data((line + "\n").utf8))
    }
}
