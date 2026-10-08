import Foundation

/// The version of the LocalizableMerger tool.
public enum LocalizableMerger {
    public static let version = "2.0.0"
}

/// An error that stops a merge run.
public enum MergerError: LocalizedError, Equatable, Sendable {
    case workDirectoryNotFound(path: String)
    case configFileNotFound(path: String)
    case invalidConfigFile(path: String, reason: String)
    case missingBaseFolder
    case baseFolderNotFound(path: String)
    case invalidGeneratedSuffix(String)
    case unreadableFile(path: String, reason: String)
    case parse(path: String, line: Int, message: String)
    case writeFailed(path: String, reason: String)

    public var errorDescription: String? {
        switch self {
        case .workDirectoryNotFound(let path):
            "The work directory does not exist: \(path)"
        case .configFileNotFound(let path):
            "The configuration file does not exist: \(path)"
        case .invalidConfigFile(let path, let reason):
            "The configuration file is not valid: \(path): \(reason)"
        case .missingBaseFolder:
            "The base folder is not set. Use --base-folder, or set baseFolder in \(Configuration.defaultFileName)."
        case .baseFolderNotFound(let path):
            "The base folder does not exist: \(path)"
        case .invalidGeneratedSuffix(let suffix):
            "The generatedSuffix value \"\(suffix)\" is not valid. Use a suffix that is not empty and has no \"/\"."
        case .unreadableFile(let path, let reason):
            "The tool cannot read the file: \(path): \(reason)"
        case .parse(let path, let line, let message):
            "\(path):\(line): \(message)"
        case .writeFailed(let path, let reason):
            "The tool cannot write the file: \(path): \(reason)"
        }
    }
}
