import Foundation
import Testing
@testable import LocalizableMergerCore

@Suite struct DiscoveryTests {
    private func relativePaths(_ files: [LocalizableFile], in directory: TempDirectory) -> [String] {
        files.map { String($0.url.path.dropFirst(directory.url.path.count + 1)) }
    }

    @Test func readsTheLanguageAndTheTableFromThePath() throws {
        let directory = try TempDirectory()
        try directory.write("Base/en.lproj/Localizable.strings", "")
        try directory.write("App/pt-BR.lproj/InfoPlist.strings", "")
        let files = Discovery.findFiles(workDirectory: directory.url, baseFolder: directory.file("Base"))
        #expect(files.map(\.language) == ["pt-BR", "en"])
        #expect(files.map(\.table) == ["InfoPlist", "Localizable"])
        #expect(files.map(\.isBase) == [false, true])
    }

    @Test func detectsTheBaseFolderByPathComponentNotBySubstring() throws {
        let directory = try TempDirectory()
        try directory.write("Base/en.lproj/Localizable.strings", "")
        try directory.write("Base2/en.lproj/Localizable.strings", "")
        try directory.write("Apps/Base/en.lproj/Localizable.strings", "")
        try directory.write("MyBase/en.lproj/Localizable.strings", "")
        let files = Discovery.findFiles(workDirectory: directory.url, baseFolder: directory.file("Base"))
        #expect(relativePaths(files.filter(\.isBase), in: directory) == ["Base/en.lproj/Localizable.strings"])
        #expect(files.count == 4)
    }

    @Test func acceptsABaseFolderPathThatIsNotStandard() throws {
        let directory = try TempDirectory()
        try directory.write("Shared/Base/en.lproj/Localizable.strings", "")
        let base = directory.file("Shared/../Shared/./Base/")
        let files = Discovery.findFiles(workDirectory: directory.url, baseFolder: base)
        #expect(files.map(\.isBase) == [true])
    }

    @Test func findsBaseFilesOutsideTheWorkDirectory() throws {
        let directory = try TempDirectory()
        try directory.write("Shared/en.lproj/Localizable.strings", "")
        try directory.write("Project/App/en.lproj/Localizable.strings", "")
        let files = Discovery.findFiles(workDirectory: directory.file("Project"), baseFolder: directory.file("Shared"))
        #expect(files.map(\.isBase) == [false, true])
    }

    @Test func ignoresGeneratedFilesAndFilesOutsideLprojFolders() throws {
        let directory = try TempDirectory()
        try directory.write("App/en.lproj/Localizable.strings", "")
        try directory.write("App/en.lproj/Localizable_generated.strings", "")
        try directory.write("App/en.lproj/Localizable.merged.strings", "")
        try directory.write("App/Loose.strings", "")
        try directory.write("App/en.lproj/Notes.txt", "")
        let files = Discovery.findFiles(
            workDirectory: directory.url, baseFolder: directory.file("Base"), generatedSuffix: "_generated"
        )
        #expect(relativePaths(files, in: directory) == [
            "App/en.lproj/Localizable.merged.strings", "App/en.lproj/Localizable.strings",
        ])
        let custom = Discovery.findFiles(
            workDirectory: directory.url, baseFolder: directory.file("Base"), generatedSuffix: ".merged"
        )
        #expect(relativePaths(custom, in: directory) == [
            "App/en.lproj/Localizable.strings", "App/en.lproj/Localizable_generated.strings",
        ])
    }

    @Test func ignoresHiddenAndDependencyDirectories() throws {
        let directory = try TempDirectory()
        try directory.write("App/en.lproj/Localizable.strings", "")
        for folder in [".build", ".git", ".hidden", "Pods", "Carthage", "DerivedData", "node_modules", "App/Pods"] {
            try directory.write("\(folder)/Lib/en.lproj/Localizable.strings", "")
        }
        let files = Discovery.findFiles(workDirectory: directory.url, baseFolder: directory.file("Base"))
        #expect(relativePaths(files, in: directory) == ["App/en.lproj/Localizable.strings"])
    }

    @Test func ignoresExcludedPaths() throws {
        let directory = try TempDirectory()
        try directory.write("App/en.lproj/Localizable.strings", "")
        try directory.write("App/en.lproj/Legacy.strings", "")
        try directory.write("Vendor/en.lproj/Localizable.strings", "")
        try directory.write("Vendor2/en.lproj/Localizable.strings", "")
        let files = Discovery.findFiles(
            workDirectory: directory.url,
            baseFolder: directory.file("Base"),
            exclude: [directory.file("Vendor"), directory.file("App/en.lproj/Legacy.strings")]
        )
        #expect(relativePaths(files, in: directory) == [
            "App/en.lproj/Localizable.strings", "Vendor2/en.lproj/Localizable.strings",
        ])
    }
}
