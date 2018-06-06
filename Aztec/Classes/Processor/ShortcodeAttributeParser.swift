import Foundation

/// A struct that parses attributes inside a shortcode and return the corresponding attributes object
///
public class ShortcodeAttributeParser {
    
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
    
    public init() {}
    
    /// Parses the provided string into attributes
    ///
    /// - Parameter text: the text to where to find the attributes
    /// - Returns: the ShortcodeAttributes parsed from the text
    ///
    public func parse(_ text: String) -> [ShortcodeAttribute] {
        var attributes = [ShortcodeAttribute]()
        
        let attributesMatches = ShortcodeAttributeParser.attributesRegex.matches(in: text, options: [], range: text.nsRange(from: text.startIndex..<text.endIndex))
        
        for attributeMatch in attributesMatches {
            if let key = attributeMatch.captureGroup(in: CaptureGroups.nameInDoubleQuotes.rawValue, text: text),
                let value = attributeMatch.captureGroup(in: CaptureGroups.valueInDoubleQuotes.rawValue, text: text) {
                attributes.append(ShortcodeAttribute(key: key, value: value))
            } else if let key = attributeMatch.captureGroup(in: CaptureGroups.nameInSingleQuotes.rawValue, text: text),
                let value = attributeMatch.captureGroup(in: CaptureGroups.valueInSingleQuotes.rawValue, text: text) {
                attributes.append(ShortcodeAttribute(key: key, value: value))
            } else if let key = attributeMatch.captureGroup(in: CaptureGroups.nameUnquoted.rawValue, text: text),
                let value = attributeMatch.captureGroup(in: CaptureGroups.valueUnquoted.rawValue, text: text) {
                attributes.append(ShortcodeAttribute(key: key, value: value))
            } else if let key = attributeMatch.captureGroup(in: CaptureGroups.justValueQuoted.rawValue, text: text) {
                attributes.append(ShortcodeAttribute(key: key))
            } else if let key = attributeMatch.captureGroup(in: CaptureGroups.justValueUnquoted.rawValue, text: text) {
                attributes.append(ShortcodeAttribute(key: key))
            }
        }
        
        return attributes
    }
    
}

