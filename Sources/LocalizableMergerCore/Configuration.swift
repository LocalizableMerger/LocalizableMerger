import Foundation
import Yams

/// The settings of a merge run.
public struct Configuration: Codable, Equatable, Sendable {
    public static let defaultFileName = "LocalizableMerger.yml"
    public static let defaultGeneratedSuffix = "_generated"

    /// The folder that contains the reference `.strings` files.
    public var baseFolder: String?
    /// The paths that the tool ignores.
    public var exclude: [String]
    /// The text that the tool adds to the name of a generated file.
    public var generatedSuffix: String

    public init(
        baseFolder: String? = nil,
        exclude: [String] = [],
        generatedSuffix: String = Configuration.defaultGeneratedSuffix
    ) {
        self.baseFolder = baseFolder
        self.exclude = exclude
        self.generatedSuffix = generatedSuffix
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        baseFolder = try container.decodeIfPresent(String.self, forKey: .baseFolder)
        exclude = try container.decodeIfPresent([String].self, forKey: .exclude) ?? []
        generatedSuffix = try container.decodeIfPresent(String.self, forKey: .generatedSuffix)
            ?? Configuration.defaultGeneratedSuffix
    }

    /// Decodes a configuration from YAML text. Empty text gives the default configuration.
    public static func decode(yaml: String) throws -> Configuration {
        if yaml.allSatisfy(\.isWhitespace) { return Configuration() }
        return try YAMLDecoder().decode(Configuration.self, from: yaml)
    }

    /// Loads the configuration file and applies the command-line value of the base folder.
    ///
    /// - Parameters:
    ///   - workDirectory: The directory that relative paths start from.
    ///   - configFile: The path that the user gave. Pass `nil` to use `LocalizableMerger.yml`.
    ///   - baseFolder: The command-line value. This value overrides the value in the file.
    /// - Throws: `MergerError.configFileNotFound` when an explicit `configFile` does not exist.
    public static func load(
        workDirectory: URL,
        configFile: String? = nil,
        baseFolder: String? = nil
    ) throws -> Configuration {
        let url = workDirectory.resolving(configFile ?? defaultFileName).standardizedFileURL
        var configuration = Configuration()
        if FileManager.default.fileExists(atPath: url.path) {
            do {
                configuration = try decode(yaml: String(contentsOf: url, encoding: .utf8))
            } catch {
                throw MergerError.invalidConfigFile(path: url.path, reason: describe(error))
            }
        } else if configFile != nil {
            throw MergerError.configFileNotFound(path: url.path)
        }
        if let baseFolder, !baseFolder.isEmpty {
            configuration.baseFolder = baseFolder
        }
        return configuration
    }

    private static func describe(_ error: any Error) -> String {
        switch error {
        case DecodingError.typeMismatch(_, let context), DecodingError.dataCorrupted(let context):
            let key = context.codingPath.map(\.stringValue).joined(separator: ".")
            return key.isEmpty ? context.debugDescription : "\(key): \(context.debugDescription)"
        default:
            return String(describing: error)
        }
    }
}
