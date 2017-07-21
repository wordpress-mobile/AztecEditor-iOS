import Foundation

/// Struct to represent the attributes of a shortcode
///
public struct HTMLAttributes {

    /// Attributes that have a form key=value or key="value" or key='value'
    public let named: [String: String]

    /// Attributes that have a form value "value"
    public let unamed: [String]

    public init(named: [String: String], unamed: [String]) {
        self.named = named
        self.unamed = unamed
    }
}

/// A struct that parses attributes inside a shortcode and return the corresponding attributes object
///
public struct HTMLAttributesParser {

    enum CaptureGroups: Int {
        case all = 0
        case nameInDoubleQuotes
        case valueInDoubleQuotes
        case nameInSingleQuotes
        case valueInSingleQuotes
        case nameUnquoted
        case valueUnquoted
        case justValueQuoted
        case justValueUnquoted
    }

    /// Regular expression to detect attributes
    /// This regular expression is reused from `shortcode_parse_atts()`
    /// in `wp-includes/shortcodes.php`.
    ///
    /// Capture groups:
    ///
    /// 1. An attribute name, that corresponds to...
    /// 2. a value in double quotes.
    /// 3. An attribute name, that corresponds to...
    /// 4. a value in single quotes.
    /// 5. An attribute name, that corresponds to...
    /// 6. an unquoted value.
    /// 7. An attribute in double quotes.
    /// 8. An unquoted attribute.
    ///
    static var attributesRegex: NSRegularExpression = {
        let doubleQuotePattern = "((?:\\w|-)+)\\s*=\\s*\"([^\"]*)\"(?:\\s|$)"
        let singleQuotePattern = "((?:\\w|-)+)\\s*=\\s*'([^']*)'(?:\\s|$)"
        let noQuotePattern = "((?:\\w|-)+)\\s*=\\s*([^\\s'\"]+)(?:\\s|$)"
        let attributesPattern: String = doubleQuotePattern + "|" + singleQuotePattern + "|" + noQuotePattern + "|\"([^\"]*)\"(?:\\s|$)|(\\S+)(?:\\s|$)"
        return try! NSRegularExpression(pattern: attributesPattern, options: .caseInsensitive)
    }()

    /// Parses the attributes from a string to the object
    ///
    /// - Parameter text: the text to where to find the attributes
    /// - Returns: the ShortcodeAttributes parsed from the text
    ///
    public static func makeAttributes(in text:String) -> HTMLAttributes {
        var namedAttributes = [String: String]()
        var unamedAttributes = [String]()

        let attributesMatches = HTMLAttributesParser.attributesRegex.matches(in: text, options: [], range: text.nsRange(from: text.startIndex..<text.endIndex))
        for attributeMatch in attributesMatches {
            if let key = attributeMatch.captureGroup(in: CaptureGroups.nameInDoubleQuotes.rawValue, text: text),
                let value = attributeMatch.captureGroup(in: CaptureGroups.valueInDoubleQuotes.rawValue, text: text) {
                namedAttributes[key] = value
            } else if let key = attributeMatch.captureGroup(in: CaptureGroups.nameInSingleQuotes.rawValue, text: text),
                let value = attributeMatch.captureGroup(in: CaptureGroups.valueInSingleQuotes.rawValue, text: text) {
                namedAttributes[key] = value
            } else if let key = attributeMatch.captureGroup(in: CaptureGroups.nameUnquoted.rawValue, text: text),
                let value = attributeMatch.captureGroup(in: CaptureGroups.valueUnquoted.rawValue, text: text) {
                namedAttributes[key] = value
            } else if let value = attributeMatch.captureGroup(in: CaptureGroups.justValueQuoted.rawValue, text: text) {
                unamedAttributes.append(value)
            } else if let value = attributeMatch.captureGroup(in: CaptureGroups.justValueUnquoted.rawValue, text: text) {
                unamedAttributes.append(value)
            }
        }
        return HTMLAttributes(named: namedAttributes, unamed: unamedAttributes)
    }
    
}
