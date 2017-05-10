import Foundation


// MARK: - String HTML Extensions
//
extension String {

    /// Encodes all of the HTML Entities: Unicode Characters will be expressed as hexadecimal.
    /// Named Entities will also be replaced, whenever `allowNamedEntities` is set to `true`.
    ///
    public func encodeHtmlEntities(allowNamedEntities: Bool = true) -> String {
        let theString = allowNamedEntities ? escapeHtmlNamedEntities() : self

        return theString.unicodeScalars.reduce("") { (out: String, char: UnicodeScalar) in
            let encoded = char.isASCII ? char.description: String(format: "&#x%2X;", char.value)
            return out + encoded
        }
    }

    /// Escapes the following HTML entities: [&, <, >, ', "]
    ///
    private func escapeHtmlNamedEntities() -> String {
        return replacingOccurrences(of: "&", with: "&amp;")
                .replacingOccurrences(of: "<", with: "&lt;")
                .replacingOccurrences(of: ">", with: "&gt;")
                .replacingOccurrences(of: "\"", with: "&quot;")
                .replacingOccurrences(of: "\'", with: "&apos;")
    }
}
