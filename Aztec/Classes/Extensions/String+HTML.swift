import Foundation


// MARK: - String HTML Extensions
//
extension String {

    /// Encodes all of the Unicode Characters as Hexa.
    ///
    public func encodeUnicodeCharactersAsHexadecimal() -> String {
        return unicodeScalars.reduce("") { (out: String, char: UnicodeScalar) in
            let encoded = char.isASCII ? char.description: String(format: "&#x%2X;", char.value)
            return out + encoded
        }
    }

    /// Escapes the following HTML entities: [&, <, >, ', "]
    ///
    public func escapeHtmlEntities() -> String {
        return replacingOccurrences(of: "&", with: "&amp;")
                .replacingOccurrences(of: "<", with: "&lt;")
                .replacingOccurrences(of: ">", with: "&gt;")
                .replacingOccurrences(of: "\"", with: "&quot;")
                .replacingOccurrences(of: "\'", with: "&apos;")
    }
}
