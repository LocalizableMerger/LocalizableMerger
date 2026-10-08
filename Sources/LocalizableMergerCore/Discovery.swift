import Foundation

/// A `.strings` file in a `<language>.lproj` folder.
public struct LocalizableFile: Equatable, Sendable {
    public let url: URL
    /// The name of the `.lproj` folder without the extension, for example `en`.
    public let language: String
    /// The file name without the extension, for example `Localizable`.
    public let table: String
    /// `true` when the file is in the base folder.
    public let isBase: Bool

    public init(url: URL, language: String, table: String, isBase: Bool) {
        self.url = url
        self.language = language
        self.table = table
        self.isBase = isBase
    }
}

/// The search for `.strings` files.
public enum Discovery {
    /// The directory names that the search always ignores. The search also ignores hidden items.
    public static let ignoredDirectories: Set<String> = [".build", "Pods", "Carthage", "DerivedData", "node_modules"]

    /// Finds the `.strings` files below the work directory and the base folder.
    ///
    /// - Returns: The files in path order. Generated files are not in the result.
    public static func findFiles(
        workDirectory: URL,
        baseFolder: URL,
        exclude: [URL] = [],
        generatedSuffix: String = Configuration.defaultGeneratedSuffix
    ) -> [LocalizableFile] {
        let workDirectory = workDirectory.normalized
        let baseFolder = baseFolder.normalized
        let exclude = exclude.map(\.normalized)
        let roots = baseFolder.isSameOrDescendant(of: workDirectory) ? [workDirectory] : [workDirectory, baseFolder]

        var files: [LocalizableFile] = []
        for root in roots {
            let enumerator = FileManager.default.enumerator(
                at: root,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            )
            while let url = (enumerator?.nextObject() as? URL)?.standardizedFileURL {
                let isDirectory = (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
                if exclude.contains(where: url.isSameOrDescendant(of:))
                    || (isDirectory && ignoredDirectories.contains(url.lastPathComponent)) {
                    enumerator?.skipDescendants()
                    continue
                }
                let folder = url.deletingLastPathComponent()
                let table = url.deletingPathExtension().lastPathComponent
                guard !isDirectory, url.pathExtension == "strings", folder.pathExtension == "lproj",
                      !table.hasSuffix(generatedSuffix) else { continue }
                files.append(LocalizableFile(
                    url: url,
                    language: folder.deletingPathExtension().lastPathComponent,
                    table: table,
                    isBase: url.isSameOrDescendant(of: baseFolder)
                ))
            }
        }
        return files.sorted { $0.url.path < $1.url.path }
    }
}

extension URL {
    /// The absolute URL without symbolic links, `.` components, and `..` components.
    var normalized: URL { standardizedFileURL.resolvingSymlinksInPath() }

    /// Returns the URL of a path. A relative path starts from this directory.
    func resolving(_ path: String) -> URL {
        path.hasPrefix("/") ? URL(fileURLWithPath: path) : appendingPathComponent(path)
    }

    /// Compares full path components. `/a/Base2` is not a descendant of `/a/Base`.
    func isSameOrDescendant(of folder: URL) -> Bool {
        let components = pathComponents
        let prefix = folder.pathComponents
        return components.count >= prefix.count && Array(components.prefix(prefix.count)) == prefix
    }
}
