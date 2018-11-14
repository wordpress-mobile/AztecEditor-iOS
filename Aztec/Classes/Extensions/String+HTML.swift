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
    public func escapeHtmlNamedEntities() -> String {
        return entities.reduce(self) { (out, entity: Entity) in
            return out.replacingOccurrences(of: entity.raw, with: entity.encoded)
        }
    }

    /// Entity Typealias Helper
    ///
    private typealias Entity = (raw: String, encoded: String)

    /// Named HTML Entities
    ///
    private var entities: [Entity] {
        return [
            ("&", "&amp;"), // IMPORTANT: keep this first to avoid replacing the ampersand from other escaped entities.
            ("<", "&lt;"),
            (String(.nonBreakingSpace), "&nbsp;"),
            (">", "&gt;")
        ]
    }
}
