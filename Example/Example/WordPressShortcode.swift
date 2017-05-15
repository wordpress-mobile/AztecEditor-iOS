import Foundation


/// Struct to represent a WordPress shortcode
/// More details here: https://codex.wordpress.org/Shortcode and here: https://en.support.wordpress.com/shortcodes/
///
public struct Shortcode {
    public enum TagType {
        case selfClosing
        case closed
        case single
    }

    public let tag: String
    public let attributes: ShortcodeAttributes
    public let type: TagType
    public let content: String?
}

/// Struct to represent the attributes of a shortcode
///
public struct ShortcodeAttributes {


    /// Attributes that have a form key=value or key="value" or key='value'
    let namedAttributes: [String: String]

    /// Attributes that have a form value "value"
    let unamedAttributes: [String]
}


/// A class that processes a string and replace the desiganted shortcode for the replacement provided strings
///
open class ShortcodeProcessor {

    public typealias ReplaceMethod = (Shortcode) -> String

    let tag: String

    let replacer: ReplaceMethod

    /// Regular expression to detect attributes
    /// Capture groups:
    ///
    /// 1. An extra `[` to allow for escaping shortcodes with double `[[]]`
    /// 2. The shortcode name
    /// 3. The shortcode argument list
    /// 4. The self closing `/`
    /// 5. The content of a shortcode when it wraps some content.
    /// 6. The closing tag.
    /// 7. An extra `]` to allow for escaping shortcodes with double `[[]]`
    ///
    lazy var regex: NSRegularExpression = {
        let pattern = "\\[(\\[?)(\(self.tag))(?![\\w-])([^\\]\\/]*(?:\\/(?!\\])[^\\]\\/]*)*?)(?:(\\/)\\]|\\](?:([^\\[]*(?:\\[(?!\\/\\2\\])[^\\[]*)*)(\\[\\/\\2\\]))?)(\\]?)"
        let regex = try! NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        return regex
    }()

    enum CaptureGroups: Int {
        case all = 0
        case extraOpen
        case name
        case arguments
        case selfClosingElement
        case content
        case closingTag
        case extraClose
    }

    public init(tag: String, replacer: @escaping ReplaceMethod) {
        self.tag = tag
        self.replacer = replacer
    }

    public func process(text: String) -> String {
        return replace(in: text, with: replacer)
    }

    /// Replace in text all the matches of the Processor with the string provided by the replacer
    ///
    /// - Parameters:
    ///   - text: the text to process
    ///   - replacer: the callback function that is invoked each time a shortcode is found to obtain the replacement
    /// - Returns: the new text after the processing is applied
    ///
    func replace(in text: String, with replacer: ReplaceMethod) -> String {
        let matches = regex.matches(in: text, options: [], range: text.nsRange(from: text.startIndex..<text.endIndex))
        var replacements = [(NSRange, String)]()
        for match in matches {
            guard match.numberOfRanges == 8 else {
                continue
            }
            var attributes = ShortcodeAttributes(namedAttributes: [:], unamedAttributes: [])
            if let attributesText = match.captureGroup(in:CaptureGroups.arguments.rawValue, text: text) {
                attributes = ShortcodeAttributesParser.makeAttributes(in: attributesText)
            }

            var type: Shortcode.TagType = .single
            if match.captureGroup(in:CaptureGroups.selfClosingElement.rawValue, text: text) != nil {
                type = .selfClosing
            } else if match.captureGroup(in:CaptureGroups.closingTag.rawValue, text: text) != nil {
                type = .closed
            }

            let content: String? = match.captureGroup(in:CaptureGroups.content.rawValue, text: text)

            let shortcode = Shortcode(tag: tag, attributes: attributes, type: type, content: content)

            let replacement = replacer(shortcode)
            replacements.append((match.range, replacement))
        }
        let resultText = replace(matches: replacements, in: text)
        return resultText
    }

    /// Replaces in text all the matches found in the range with the provided string
    ///
    /// - Parameters:
    ///   - matches: an array with tupples that designated the range of the match and the replacement string to apply
    ///   - text: the original text to where the replacement will be done
    /// - Returns: the new string with the replacements done
    ///
    func replace(matches: [(NSRange, String)], in text: String) -> String {
        let mutableString = NSMutableString(string: text)
        var offset = 0
        for (range, replacement) in matches {
            let lengthBefore = mutableString.length
            let offsetRange = NSRange(location: range.location + offset, length: range.length)
            mutableString.replaceCharacters(in: offsetRange, with: replacement)
            let lengthAfter = mutableString.length
            offset += (lengthAfter - lengthBefore)
        }
        return mutableString as String
    }
}


/// A struct that parses attributes inside a shortcode and return the corresponding attributes object
///
public struct ShortcodeAttributesParser {

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
    /// 7. A numeric attribute in double quotes.
    /// 8. An unquoted numeric attribute.
    ///
    static var attributesRegex: NSRegularExpression = {
        let attributesPattern: String = "(\\w+)\\s*=\\s*\"([^\"]*)\"(?:\\s|$)|(\\w+)\\s*=\\s*'([^']*)'(?:\\s|$)|(\\w+)\\s*=\\s*([^\\s'\"]+)(?:\\s|$)|\"([^\"]*)\"(?:\\s|$)|(\\S+)(?:\\s|$)"
        return try! NSRegularExpression(pattern: attributesPattern, options: .caseInsensitive)
    }()

    /// Parses the attributes from a string to the object
    ///
    /// - Parameter text: the text to where to find the attributes
    /// - Returns: the ShortcodeAttributes parsed from the text
    ///
    static func makeAttributes(in text:String) -> ShortcodeAttributes {
        var namedAttributes = [String: String]()
        var unamedAttributes = [String]()

        let attributesMatches = ShortcodeAttributesParser.attributesRegex.matches(in: text, options: [], range: text.nsRange(from: text.startIndex..<text.endIndex))
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
        return ShortcodeAttributes(namedAttributes: namedAttributes, unamedAttributes: unamedAttributes)
    }

}

extension NSTextCheckingResult {

    /// Returns the match for the corresponding capture group position in a text
    ///
    /// - Parameters:
    ///   - position: the capture group position
    ///   - text: the string where the match was detected
    /// - Returns: the string with the captured group text
    ///
    func captureGroup(in position: Int, text: String) -> String? {
        guard position < numberOfRanges else {
            return nil
        }

        let nsrange = rangeAt(position)

        guard nsrange.location != NSNotFound else {
            return nil
        }

        let range = text.range(from: nsrange)
        let captureGroup = text.substring(with: range)
        return captureGroup
    }
}
