import Foundation
import Testing
@testable import LocalizableMergerCore

@Suite struct StringsParserTests {
    @Test func parsesQuotedEntries() throws {
        let table = try StringsParser.parse("\"a\" = \"1\";\n\"b\"=\"2\";")
        #expect(table.entries == ["a": "1", "b": "2"])
        #expect(table.duplicateKeys.isEmpty)
    }

    @Test func parsesEmptyText() throws {
        #expect(try StringsParser.parse("").entries.isEmpty)
        #expect(try StringsParser.parse("  \n// only a comment\n").entries.isEmpty)
    }

    @Test func parsesUnquotedKeysAndValues() throws {
        let table = try StringsParser.parse("key_1 = value;\nscreen.title-2 = \"Title\";\n\"k\" = 42;")
        #expect(table.entries == ["key_1": "value", "screen.title-2": "Title", "k": "42"])
    }

    @Test func usesTheKeyAsValueWhenTheEntryHasNoValue() throws {
        #expect(try StringsParser.parse("\"OK\";").entries == ["OK": "OK"])
    }

    @Test func ignoresComments() throws {
        let text = """
            // line comment
            /* block
               comment */ "a" /* inline */ = "1"; // end comment
            "b" = "// not a comment /* also not */";
            """
        #expect(try StringsParser.parse(text).entries == ["a": "1", "b": "// not a comment /* also not */"])
    }

    @Test(arguments: [
        (#""\"quoted\"""#, "\"quoted\""),
        (#""back\\slash""#, "back\\slash"),
        (#""line\nbreak""#, "line\nbreak"),
        (#""tab\there""#, "tab\there"),
        (#""return\rhere""#, "return\rhere"),
        (#""\U00e9\u00F1""#, "éñ"),
        (#""\Ud83d\Ude00""#, "😀"),
        (#""it\'s""#, "it's"),
    ])
    func decodesEscapes(literal: String, expected: String) throws {
        #expect(try StringsParser.parse("\"k\" = \(literal);").entries["k"] == expected)
    }

    @Test func keepsLineBreaksInMultiLineValues() throws {
        let table = try StringsParser.parse("\"k\" = \"first\nsecond\";\n\"next\" = \"x\";")
        #expect(table.entries == ["k": "first\nsecond", "next": "x"])
    }

    @Test func reportsDuplicateKeysAndKeepsTheLastValue() throws {
        let table = try StringsParser.parse("\"a\" = \"1\";\n\"b\" = \"x\";\n\"a\" = \"2\";\n\"a\" = \"3\";")
        #expect(table.entries == ["a": "3", "b": "x"])
        #expect(table.duplicateKeys == ["a"])
    }

    @Test(arguments: [
        ("\"a\" = \"1\"\n\"b\" = \"2\";", 1),          // no semicolon
        ("\"a\" = \"1\";\n\"b\" \"2\";", 2),           // no equals sign
        ("\"a\" = \"1\";\n\n\"b\" = \"open;\n", 3),    // quoted text has no end
        ("\"a\" = \"1\";\n/* open", 2),                // comment has no end
        ("\"a\" = ;", 1),                              // no value
        ("\"a\" =", 1),                                // file ends
        ("\"a\" = \"\\U12\";", 1),                     // short Unicode escape
        ("\"a\" = \"\\Ud83d\";", 1),                   // surrogate without its pair
        ("= \"1\";", 1),                               // no key
    ])
    func reportsSyntaxErrorsWithTheLine(text: String, line: Int) {
        #expect { try StringsParser.parse(text) } throws: { error in
            (error as? StringsParseError)?.line == line
        }
    }

    @Test(arguments: [String.Encoding.utf16LittleEndian, .utf16BigEndian])
    func readsUTF16WithByteOrderMark(encoding: String.Encoding) throws {
        let directory = try TempDirectory()
        let text = "\"saludo\" = \"¡Hola, señor! 😀\";"
        let mark: [UInt8] = encoding == .utf16LittleEndian ? [0xFF, 0xFE] : [0xFE, 0xFF]
        let url = directory.file("utf16.strings")
        try (Data(mark) + #require(text.data(using: encoding))).write(to: url)
        #expect(try StringsParser.parse(contentsOf: url).entries == ["saludo": "¡Hola, señor! 😀"])
    }

    @Test func readsUTF8WithAndWithoutByteOrderMark() throws {
        let directory = try TempDirectory()
        let plain = try directory.write("plain.strings", "\"k\" = \"aplicación\";")
        let marked = directory.file("marked.strings")
        try (Data([0xEF, 0xBB, 0xBF]) + Data("\"k\" = \"aplicación\";".utf8)).write(to: marked)
        #expect(try StringsParser.parse(contentsOf: plain).entries == ["k": "aplicación"])
        #expect(try StringsParser.parse(contentsOf: marked).entries == ["k": "aplicación"])
    }

    @Test func reportsTheFileAndTheLineOfAParseError() throws {
        let directory = try TempDirectory()
        let url = try directory.write("en.lproj/Bad.strings", "\"a\" = \"1\";\n\"b\" = \"2\"\n")
        #expect(throws: MergerError.parse(path: url.path, line: 2, message: "Expected \";\" after the entry \"b\".")) {
            try StringsParser.parse(contentsOf: url)
        }
        let description = MergerError.parse(path: url.path, line: 2, message: "m").errorDescription
        #expect(description == "\(url.path):2: m")
    }

    @Test func reportsAFileThatDoesNotExist() throws {
        let directory = try TempDirectory()
        #expect {
            try StringsParser.parse(contentsOf: directory.file("absent.strings"))
        } throws: { error in
            if case MergerError.unreadableFile = error { true } else { false }
        }
    }
}
