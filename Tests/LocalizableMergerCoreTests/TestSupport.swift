import Foundation
import Testing
@testable import LocalizableMergerCore

/// A temporary directory that the test removes at the end.
final class TempDirectory {
    let url: URL

    init() throws {
        url = FileManager.default.temporaryDirectory
            .appendingPathComponent("LocalizableMergerTests-\(UUID().uuidString)", isDirectory: true)
            .normalized
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    deinit {
        try? FileManager.default.removeItem(at: url)
    }

    func file(_ path: String) -> URL {
        url.appendingPathComponent(path)
    }

    @discardableResult
    func write(_ path: String, _ text: String, encoding: String.Encoding = .utf8) throws -> URL {
        let target = file(path)
        try FileManager.default.createDirectory(
            at: target.deletingLastPathComponent(), withIntermediateDirectories: true
        )
        try #require(text.data(using: encoding)).write(to: target)
        return target
    }

    func read(_ path: String) throws -> String {
        try String(contentsOf: file(path), encoding: .utf8)
    }

    func exists(_ path: String) -> Bool {
        FileManager.default.fileExists(atPath: file(path).path)
    }
}
