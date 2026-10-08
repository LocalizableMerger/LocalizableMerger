import Foundation
import Testing
@testable import LocalizableMergerCore

@Suite struct ConfigurationTests {
    @Test func decodesAllKeys() throws {
        let yaml = """
            baseFolder: Project/Base
            exclude:
              - Vendor
              - Legacy/Old
            generatedSuffix: .merged
            """
        #expect(try Configuration.decode(yaml: yaml) == Configuration(
            baseFolder: "Project/Base", exclude: ["Vendor", "Legacy/Old"], generatedSuffix: ".merged"
        ))
    }

    @Test func usesDefaultsForAbsentKeys() throws {
        #expect(try Configuration.decode(yaml: "baseFolder: Base") == Configuration(baseFolder: "Base"))
        #expect(try Configuration.decode(yaml: "exclude: [Vendor]").baseFolder == nil)
        #expect(try Configuration.decode(yaml: " \n") == Configuration())
        #expect(Configuration().generatedSuffix == "_generated")
        #expect(Configuration().exclude.isEmpty)
    }

    @Test func loadsTheDefaultFileFromTheWorkDirectory() throws {
        let directory = try TempDirectory()
        try directory.write("LocalizableMerger.yml", "baseFolder: FromFile\n")
        #expect(try Configuration.load(workDirectory: directory.url).baseFolder == "FromFile")
    }

    @Test func acceptsAnAbsentDefaultFile() throws {
        let directory = try TempDirectory()
        #expect(try Configuration.load(workDirectory: directory.url) == Configuration())
        #expect(try Configuration.load(workDirectory: directory.url, baseFolder: "Flag").baseFolder == "Flag")
    }

    @Test func throwsWhenAnExplicitFileDoesNotExist() throws {
        let directory = try TempDirectory()
        #expect(throws: MergerError.configFileNotFound(path: directory.file("custom.yml").path)) {
            try Configuration.load(workDirectory: directory.url, configFile: "custom.yml")
        }
        #expect(throws: MergerError.configFileNotFound(path: directory.file("LocalizableMerger.yml").path)) {
            try Configuration.load(workDirectory: directory.url, configFile: "LocalizableMerger.yml")
        }
    }

    @Test func loadsAnExplicitFileRelativeToTheWorkDirectoryOrAbsolute() throws {
        let directory = try TempDirectory()
        let url = try directory.write("config/custom.yml", "baseFolder: Custom\n")
        try directory.write("LocalizableMerger.yml", "baseFolder: Default\n")
        #expect(try Configuration.load(workDirectory: directory.url, configFile: "config/custom.yml").baseFolder == "Custom")
        #expect(try Configuration.load(workDirectory: directory.file("other"), configFile: url.path).baseFolder == "Custom")
    }

    @Test func commandLineValueOverridesTheFile() throws {
        let directory = try TempDirectory()
        try directory.write("LocalizableMerger.yml", "baseFolder: FromFile\nexclude: [Vendor]\n")
        let configuration = try Configuration.load(workDirectory: directory.url, baseFolder: "FromFlag")
        #expect(configuration == Configuration(baseFolder: "FromFlag", exclude: ["Vendor"]))
        // An empty value is the same as no value. Version 1.x used "" as the default.
        #expect(try Configuration.load(workDirectory: directory.url, baseFolder: "").baseFolder == "FromFile")
    }

    @Test(arguments: ["baseFolder: [a, b]", "exclude: Vendor", "baseFolder: \"open"])
    func throwsOnAnInvalidFile(yaml: String) throws {
        let directory = try TempDirectory()
        try directory.write("LocalizableMerger.yml", yaml)
        #expect {
            try Configuration.load(workDirectory: directory.url)
        } throws: { error in
            if case MergerError.invalidConfigFile = error { true } else { false }
        }
    }
}
