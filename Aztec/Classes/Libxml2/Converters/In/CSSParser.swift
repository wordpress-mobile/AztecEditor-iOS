import Foundation

class CSSParser {

    static let attributeSeparator = ";"
    static let keyValueSeparator = ":"

    /// Parses the provided inline CSS string
    ///
    /// - Parameters:
    ///     - cssAttribute: a string containing inline CSS as read from an HTML document.
    ///
    /// - Returns: an array of `CSSAttribute` objects.
    ///
    func parse(_ css: String) -> [CSSAttribute] {

        guard css.characters.count > 0 else {
            return []
        }

        let attributeStrings = css.components(separatedBy: CSSParser.attributeSeparator)

        return parse(attributeStrings)
    }

    /// Parses the provided CSS attributes (each string representing a single attribute).
    ///
    /// - Parameters:
    ///     - cssAttributes: an array of strings containing the definition for CSS attributes.
    ///
    /// - Returns: an array of `CSSAttribute` objects.
    ///
    private func parse(_ cssAttributes: [String]) -> [CSSAttribute] {

        let attributes = cssAttributes.flatMap { (cssAttribute) -> CSSAttribute? in
            return parse(cssAttribute: cssAttribute)
        }
        
        return attributes
    }

    /// Parses the provided CSS attribute.
    ///
    /// - Parameters:
    ///     - cssAttribute: a string containing the definition of a CSS attributes.
    ///
    /// - Returns: the parsed `CSSAttribute` object.
    ///
    private func parse(cssAttribute: String) -> CSSAttribute {

        guard let keyValueSeparatorRange = cssAttribute.range(of: CSSParser.keyValueSeparator) else {
            return CSSAttribute(name: cssAttribute)
        }

        let name = cssAttribute.substring(to: keyValueSeparatorRange.lowerBound)

        guard keyValueSeparatorRange.upperBound != cssAttribute.endIndex else {
            return CSSAttribute(name: name)
        }

        let valueStartIndex = cssAttribute.index(after: keyValueSeparatorRange.upperBound)
        let value = cssAttribute.substring(from: valueStartIndex)

        return CSSAttribute(name: name, value: value)

    }
}
