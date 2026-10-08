import Foundation

/// The content of one `.strings` file.
public struct StringsTable: Equatable, Sendable {
    public var entries: [String: String]
    /// The keys that occur more than one time. The last value wins.
    public var duplicateKeys: [String]

    public init(entries: [String: String] = [:], duplicateKeys: [String] = []) {
        self.entries = entries
        self.duplicateKeys = duplicateKeys
    }
}

/// A syntax error in `.strings` text.
public struct StringsParseError: Error, Equatable, Sendable {
    public let line: Int
    public let message: String
}

/// A parser for the `.strings` format.
///
/// The parser accepts quoted and unquoted tokens, `//` and `/* */` comments, escape sequences,
/// and values that continue on more than one line.
public enum StringsParser {
    public static func parse(_ text: String) throws(StringsParseError) -> StringsTable {
        var scanner = Scanner(text)
        var table = StringsTable()
        while true {
            try scanner.skipTrivia()
            guard scanner.peek != nil else { return table }
            let key = try scanner.token(expected: "a key")
            var endLine = scanner.line
            try scanner.skipTrivia()
            var value = key
            if scanner.peek == "=" {
                scanner.advance()
                try scanner.skipTrivia()
                value = try scanner.token(expected: "a value")
                endLine = scanner.line
                try scanner.skipTrivia()
            }
            guard scanner.peek == ";" else {
                throw StringsParseError(line: endLine, message: "Expected \";\" after the entry \"\(key)\".")
            }
            scanner.advance()
            if table.entries[key] != nil, !table.duplicateKeys.contains(key) {
                table.duplicateKeys.append(key)
            }
            table.entries[key] = value
        }
    }

    /// Reads and parses a file. The file can be UTF-8, or UTF-16 with a byte order mark.
    public static func parse(contentsOf url: URL) throws -> StringsTable {
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw MergerError.unreadableFile(path: url.path, reason: error.localizedDescription)
        }
        guard let text = decode(data) else {
            throw MergerError.unreadableFile(path: url.path, reason: "The text is not UTF-8 or UTF-16.")
        }
        do {
            return try parse(text)
        } catch {
            throw MergerError.parse(path: url.path, line: error.line, message: error.message)
        }
    }

    /// Decodes UTF-8 or UTF-16 data. A byte order mark selects UTF-16.
    public static func decode(_ data: Data) -> String? {
        if data.starts(with: [0xFF, 0xFE]) || data.starts(with: [0xFE, 0xFF]) {
            return String(data: data, encoding: .utf16)
        }
        if data.starts(with: [0xEF, 0xBB, 0xBF]) {
            return String(data: data.dropFirst(3), encoding: .utf8)
        }
        return String(data: data, encoding: .utf8) ?? String(data: data, encoding: .utf16)
    }
}

private struct Scanner {
    private let scalars: [Unicode.Scalar]
    private var index = 0
    private(set) var line = 1

    init(_ text: String) {
        scalars = Array(text.unicodeScalars)
    }

    var peek: Unicode.Scalar? { index < scalars.count ? scalars[index] : nil }
    private var peekNext: Unicode.Scalar? { index + 1 < scalars.count ? scalars[index + 1] : nil }

    @discardableResult
    mutating func advance() -> Unicode.Scalar {
        let scalar = scalars[index]
        index += 1
        if scalar == "\n" { line += 1 }
        return scalar
    }

    /// Skips white space and comments.
    mutating func skipTrivia() throws(StringsParseError) {
        while let scalar = peek {
            if scalar.properties.isWhitespace || scalar == "\u{FEFF}" {
                advance()
            } else if scalar == "/", peekNext == "/" {
                while let next = peek, next != "\n" { advance() }
            } else if scalar == "/", peekNext == "*" {
                let start = line
                advance()
                advance()
                while !(peek == "*" && peekNext == "/") {
                    guard peek != nil else {
                        throw StringsParseError(line: start, message: "The comment has no end.")
                    }
                    advance()
                }
                advance()
                advance()
            } else {
                return
            }
        }
    }

    /// Reads a quoted or an unquoted token.
    mutating func token(expected: String) throws(StringsParseError) -> String {
        guard let first = peek else {
            throw StringsParseError(line: line, message: "Expected \(expected), but the file ends.")
        }
        if first == "\"" { return try quoted() }
        var result = String.UnicodeScalarView()
        while let scalar = peek, Self.isBare(scalar) {
            result.append(advance())
        }
        guard !result.isEmpty else {
            throw StringsParseError(line: line, message: "Expected \(expected), but found \"\(first)\".")
        }
        return String(result)
    }

    private static func isBare(_ scalar: Unicode.Scalar) -> Bool {
        scalar.properties.isAlphabetic || ("0"..."9").contains(scalar) || "_$:.-".unicodeScalars.contains(scalar)
    }

    private mutating func quoted() throws(StringsParseError) -> String {
        let start = line
        let unterminated = StringsParseError(line: start, message: "The quoted text has no end.")
        advance()
        var result = String.UnicodeScalarView()
        while true {
            guard peek != nil else { throw unterminated }
            let scalar = advance()
            if scalar == "\"" { return String(result) }
            guard scalar == "\\" else {
                result.append(scalar)
                continue
            }
            guard peek != nil else { throw unterminated }
            let escaped = advance()
            switch escaped {
            case "n": result.append("\n")
            case "t": result.append("\t")
            case "r": result.append("\r")
            case "U", "u": result.append(try unicodeEscape())
            default: result.append(escaped)
            }
        }
    }

    /// Reads the digits of a `\Uxxxx` escape. A surrogate pair uses two escapes.
    private mutating func unicodeEscape() throws(StringsParseError) -> Unicode.Scalar {
        let invalid = StringsParseError(line: line, message: "The Unicode escape is not valid.")
        var unit = try hexUnit()
        if (0xD800...0xDBFF).contains(unit) {
            guard peek == "\\", peekNext == "U" || peekNext == "u" else { throw invalid }
            advance()
            advance()
            let low = try hexUnit()
            guard (0xDC00...0xDFFF).contains(low) else { throw invalid }
            unit = 0x10000 + ((unit - 0xD800) << 10) + (low - 0xDC00)
        }
        guard let scalar = Unicode.Scalar(unit) else { throw invalid }
        return scalar
    }

    private mutating func hexUnit() throws(StringsParseError) -> UInt32 {
        var value: UInt32 = 0
        for _ in 0..<4 {
            guard let scalar = peek, scalar.isASCII, let digit = Character(scalar).hexDigitValue else {
                throw StringsParseError(line: line, message: "A Unicode escape needs four hexadecimal digits.")
            }
            advance()
            value = value * 16 + UInt32(digit)
        }
        return value
    }
}
