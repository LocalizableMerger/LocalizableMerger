import Foundation

/// The result of a merge run.
public struct MergeReport: Equatable, Sendable {
    public enum Status: Equatable, Sendable {
        /// The generated file did not exist before the run.
        case created
        /// The generated file existed, and its content was stale.
        case updated
        /// The generated file was correct before the run.
        case unchanged
    }

    public struct Output: Equatable, Sendable {
        public let source: URL
        public let base: URL
        public let output: URL
        public let keyCount: Int
        public let status: Status
    }

    /// A list of keys that belongs to one file.
    public struct KeyWarning: Equatable, Sendable {
        public let file: URL
        public let keys: [String]
    }

    /// The normalized work directory of the run.
    public let workDirectory: URL
    /// One item for each target file that has a base file.
    public var outputs: [Output] = []
    /// The target files that the run skipped. No base file has the same language and table.
    public var missingBase: [LocalizableFile] = []
    /// The keys that are in a target file but not in its base file.
    public var orphanKeys: [KeyWarning] = []
    /// The keys that occur more than one time in one file.
    public var duplicateKeys: [KeyWarning] = []

    /// The outputs that were absent or stale before the run.
    public var changed: [Output] { outputs.filter { $0.status != .unchanged } }
    public var unchanged: [Output] { outputs.filter { $0.status == .unchanged } }
    /// `true` when no generated file was absent or stale before the run.
    public var isUpToDate: Bool { changed.isEmpty }

    /// Returns the path of a URL relative to the work directory.
    public func relativePath(_ url: URL) -> String {
        guard url.isSameOrDescendant(of: workDirectory) else { return url.path }
        return url.pathComponents.dropFirst(workDirectory.pathComponents.count).joined(separator: "/")
    }
}

/// The merge operation.
public enum Merger {
    /// Merges each target `.strings` file with the base file of the same language and table.
    ///
    /// - Parameters:
    ///   - workDirectory: The root of the search. Relative paths in `configuration` start here.
    ///   - configuration: The settings of the run.
    ///   - write: Pass `false` to get the report and write no files.
    public static func run(
        workDirectory: URL,
        configuration: Configuration,
        write: Bool = true
    ) throws -> MergeReport {
        let fileManager = FileManager.default
        let workDirectory = workDirectory.normalized
        guard fileManager.isDirectory(workDirectory) else {
            throw MergerError.workDirectoryNotFound(path: workDirectory.path)
        }
        guard let baseFolderPath = configuration.baseFolder, !baseFolderPath.isEmpty else {
            throw MergerError.missingBaseFolder
        }
        let baseFolder = workDirectory.resolving(baseFolderPath).normalized
        guard fileManager.isDirectory(baseFolder) else {
            throw MergerError.baseFolderNotFound(path: baseFolder.path)
        }
        let suffix = configuration.generatedSuffix
        guard !suffix.isEmpty, !suffix.contains("/") else {
            throw MergerError.invalidGeneratedSuffix(suffix)
        }

        let files = Discovery.findFiles(
            workDirectory: workDirectory,
            baseFolder: baseFolder,
            exclude: configuration.exclude.map(workDirectory.resolving),
            generatedSuffix: suffix
        )
        var report = MergeReport(workDirectory: workDirectory)

        // The first base file in path order wins when two base files have the same language and table.
        var bases: [String: (file: LocalizableFile, table: StringsTable)] = [:]
        for file in files where file.isBase && bases[file.pairKey] == nil {
            bases[file.pairKey] = (file, try parse(file, into: &report))
        }

        for target in files where !target.isBase {
            guard let base = bases[target.pairKey] else {
                report.missingBase.append(target)
                continue
            }
            let table = try parse(target, into: &report)
            let orphans = table.entries.keys.filter { base.table.entries[$0] == nil }.sorted()
            if !orphans.isEmpty {
                report.orphanKeys.append(.init(file: target.url, keys: orphans))
            }

            let merged = base.table.entries.merging(table.entries) { _, override in override }
            let text = StringsWriter.render(merged)
            let output = target.url.deletingLastPathComponent()
                .appendingPathComponent(target.table + suffix + ".strings")
            let existing = try? Data(contentsOf: output)
            let status: MergeReport.Status =
                existing == nil ? .created : existing == Data(text.utf8) ? .unchanged : .updated
            if write, status != .unchanged {
                try StringsWriter.write(text, to: output)
            }
            report.outputs.append(.init(
                source: target.url, base: base.file.url, output: output, keyCount: merged.count, status: status
            ))
        }
        return report
    }

    private static func parse(_ file: LocalizableFile, into report: inout MergeReport) throws -> StringsTable {
        let table = try StringsParser.parse(contentsOf: file.url)
        if !table.duplicateKeys.isEmpty {
            report.duplicateKeys.append(.init(file: file.url, keys: table.duplicateKeys))
        }
        return table
    }
}

private extension LocalizableFile {
    var pairKey: String { language + "/" + table }
}

private extension FileManager {
    func isDirectory(_ url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        return fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue
    }
}
