import Foundation
import Testing
@testable import LocalizableMergerCore

@Suite struct MergerTests {
    /// A project with one base folder and two apps.
    private func makeProject() throws -> TempDirectory {
        let directory = try TempDirectory()
        try directory.write("Base/en.lproj/Localizable.strings", "\"a\" = \"Base A\";\n\"b\" = \"Base B\";\n")
        try directory.write("Base/en.lproj/InfoPlist.strings", "\"CFBundleName\" = \"Base\";\n")
        try directory.write("Base/es.lproj/Localizable.strings", "\"a\" = \"Base A (es)\";\n")
        try directory.write("AppA/en.lproj/Localizable.strings", "\"b\" = \"App \\\"B\\\"\";\n")
        try directory.write("AppA/en.lproj/InfoPlist.strings", "\"CFBundleName\" = \"App A\";\n")
        try directory.write("AppB/es.lproj/Localizable.strings", "\"a\" = \"App A (es)\";\n")
        return directory
    }

    private let configuration = Configuration(baseFolder: "Base")

    @Test func mergesEachTargetWithTheBaseOfTheSameLanguageAndTable() throws {
        let directory = try makeProject()
        let report = try Merger.run(workDirectory: directory.url, configuration: configuration)

        #expect(try directory.read("AppA/en.lproj/Localizable_generated.strings")
            == StringsWriter.header + "\n\n\"a\" = \"Base A\";\n\"b\" = \"App \\\"B\\\"\";\n")
        #expect(try directory.read("AppA/en.lproj/InfoPlist_generated.strings")
            == StringsWriter.header + "\n\n\"CFBundleName\" = \"App A\";\n")
        #expect(try directory.read("AppB/es.lproj/Localizable_generated.strings")
            == StringsWriter.header + "\n\n\"a\" = \"App A (es)\";\n")
        #expect(!directory.exists("Base/en.lproj/Localizable_generated.strings"))

        #expect(report.outputs.map(\.status) == [.created, .created, .created])
        #expect(report.outputs.map(\.keyCount) == [1, 2, 1])
        #expect(report.outputs.map { report.relativePath($0.base) } == [
            "Base/en.lproj/InfoPlist.strings", "Base/en.lproj/Localizable.strings", "Base/es.lproj/Localizable.strings",
        ])
        #expect(report.missingBase.isEmpty && report.orphanKeys.isEmpty && report.duplicateKeys.isEmpty)
    }

    @Test func reportsUnchangedFilesOnTheSecondRun() throws {
        let directory = try makeProject()
        _ = try Merger.run(workDirectory: directory.url, configuration: configuration)
        let report = try Merger.run(workDirectory: directory.url, configuration: configuration)
        #expect(report.outputs.map(\.status) == [.unchanged, .unchanged, .unchanged])
        #expect(report.isUpToDate)
        #expect(report.unchanged.count == 3)
    }

    @Test func writesNoFilesWhenWriteIsFalse() throws {
        let directory = try makeProject()
        let report = try Merger.run(workDirectory: directory.url, configuration: configuration, write: false)
        #expect(report.outputs.map(\.status) == [.created, .created, .created])
        #expect(!report.isUpToDate)
        #expect(!directory.exists("AppA/en.lproj/Localizable_generated.strings"))
    }

    @Test func detectsStaleFilesAndKeepsThemWhenWriteIsFalse() throws {
        let directory = try makeProject()
        _ = try Merger.run(workDirectory: directory.url, configuration: configuration)
        try directory.write("Base/en.lproj/Localizable.strings", "\"a\" = \"New A\";\n\"b\" = \"Base B\";\n")
        let before = try directory.read("AppA/en.lproj/Localizable_generated.strings")

        let check = try Merger.run(workDirectory: directory.url, configuration: configuration, write: false)
        #expect(check.changed.map { check.relativePath($0.output) } == ["AppA/en.lproj/Localizable_generated.strings"])
        #expect(check.changed.map(\.status) == [.updated])
        #expect(try directory.read("AppA/en.lproj/Localizable_generated.strings") == before)

        let update = try Merger.run(workDirectory: directory.url, configuration: configuration)
        #expect(update.changed.map(\.status) == [.updated])
        #expect(try directory.read("AppA/en.lproj/Localizable_generated.strings").contains("\"a\" = \"New A\";"))
        #expect(try Merger.run(workDirectory: directory.url, configuration: configuration, write: false).isUpToDate)
    }

    @Test func skipsTargetsThatHaveNoBaseForTheLanguageAndTable() throws {
        let directory = try makeProject()
        try directory.write("AppA/fr.lproj/Localizable.strings", "\"a\" = \"A\";")
        try directory.write("AppB/es.lproj/InfoPlist.strings", "\"CFBundleName\" = \"B\";")
        let report = try Merger.run(workDirectory: directory.url, configuration: configuration)
        #expect(report.missingBase.map { report.relativePath($0.url) } == [
            "AppA/fr.lproj/Localizable.strings", "AppB/es.lproj/InfoPlist.strings",
        ])
        #expect(!directory.exists("AppA/fr.lproj/Localizable_generated.strings"))
        #expect(!directory.exists("AppB/es.lproj/InfoPlist_generated.strings"))
    }

    @Test func reportsOrphanKeysAndKeepsThemInTheOutput() throws {
        let directory = try makeProject()
        try directory.write("AppA/en.lproj/Localizable.strings", "\"z\" = \"Z\";\n\"b\" = \"B\";\n\"only\" = \"x\";")
        let report = try Merger.run(workDirectory: directory.url, configuration: configuration)
        #expect(report.orphanKeys == [
            .init(file: directory.file("AppA/en.lproj/Localizable.strings"), keys: ["only", "z"]),
        ])
        #expect(try directory.read("AppA/en.lproj/Localizable_generated.strings").contains("\"only\" = \"x\";"))
    }

    @Test func reportsDuplicateKeysInBaseAndTargetFiles() throws {
        let directory = try makeProject()
        try directory.write("Base/es.lproj/Localizable.strings", "\"a\" = \"1\";\n\"a\" = \"2\";")
        try directory.write("AppB/es.lproj/Localizable.strings", "\"x\" = \"1\";\n\"x\" = \"2\";")
        let report = try Merger.run(workDirectory: directory.url, configuration: configuration)
        #expect(report.duplicateKeys == [
            .init(file: directory.file("Base/es.lproj/Localizable.strings"), keys: ["a"]),
            .init(file: directory.file("AppB/es.lproj/Localizable.strings"), keys: ["x"]),
        ])
        #expect(try directory.read("AppB/es.lproj/Localizable_generated.strings").contains("\"a\" = \"2\";"))
    }

    @Test func usesTheConfiguredSuffixAndExcludeList() throws {
        let directory = try makeProject()
        let custom = Configuration(baseFolder: "Base", exclude: ["AppB"], generatedSuffix: ".merged")
        let report = try Merger.run(workDirectory: directory.url, configuration: custom)
        #expect(report.outputs.map { report.relativePath($0.output) } == [
            "AppA/en.lproj/InfoPlist.merged.strings", "AppA/en.lproj/Localizable.merged.strings",
        ])
        // The second run does not use a generated file as a target.
        #expect(try Merger.run(workDirectory: directory.url, configuration: custom).outputs.count == 2)
    }

    @Test func throwsWhenTheBaseFolderIsNotSet() throws {
        let directory = try makeProject()
        #expect(throws: MergerError.missingBaseFolder) {
            try Merger.run(workDirectory: directory.url, configuration: Configuration())
        }
        #expect(throws: MergerError.missingBaseFolder) {
            try Merger.run(workDirectory: directory.url, configuration: Configuration(baseFolder: ""))
        }
    }

    @Test func throwsWhenAFolderDoesNotExist() throws {
        let directory = try makeProject()
        #expect(throws: MergerError.baseFolderNotFound(path: directory.file("Absent").path)) {
            try Merger.run(workDirectory: directory.url, configuration: Configuration(baseFolder: "Absent"))
        }
        #expect(throws: MergerError.workDirectoryNotFound(path: directory.file("Nowhere").path)) {
            try Merger.run(workDirectory: directory.file("Nowhere"), configuration: configuration)
        }
    }

    @Test(arguments: ["", "a/b"])
    func throwsWhenTheSuffixIsNotValid(suffix: String) throws {
        let directory = try makeProject()
        #expect(throws: MergerError.invalidGeneratedSuffix(suffix)) {
            try Merger.run(
                workDirectory: directory.url,
                configuration: Configuration(baseFolder: "Base", generatedSuffix: suffix)
            )
        }
    }

    @Test func throwsOnASyntaxErrorAndNamesTheFile() throws {
        let directory = try makeProject()
        let bad = try directory.write("AppB/es.lproj/Localizable.strings", "\"a\" = \"1\";\n\"b\" = ;\n")
        #expect {
            try Merger.run(workDirectory: directory.url, configuration: configuration)
        } throws: { error in
            guard case MergerError.parse(let path, let line, _) = error else { return false }
            return path == bad.path && line == 2
        }
    }

    /// The `Example` folder of the repository is the reference for the output format.
    @Test func regeneratesTheExampleFolder() throws {
        let example = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Example")
        let directory = try TempDirectory()
        let copy = directory.file("Example")
        try FileManager.default.copyItem(at: example, to: copy)
        let generated = [
            "AppA/en.lproj/Localizable_generated.strings",
            "AppB/en.lproj/Localizable_generated.strings",
            "AppB/es.lproj/Localizable_generated.strings",
        ]
        for path in generated {
            try FileManager.default.removeItem(at: copy.appendingPathComponent(path))
        }

        let configuration = try Configuration.load(workDirectory: copy)
        let report = try Merger.run(workDirectory: copy, configuration: configuration)
        #expect(report.outputs.map { report.relativePath($0.output) } == generated)
        #expect(report.missingBase.isEmpty && report.orphanKeys.isEmpty && report.duplicateKeys.isEmpty)
        for path in generated {
            let expected = try String(contentsOf: example.appendingPathComponent(path), encoding: .utf8)
            #expect(try String(contentsOf: copy.appendingPathComponent(path), encoding: .utf8) == expected)
        }
    }
}
