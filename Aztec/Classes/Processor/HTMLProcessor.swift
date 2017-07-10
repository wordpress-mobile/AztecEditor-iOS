import Foundation


/// Struct to represent a HTML element
///
public struct HTMLElement {
    public enum TagType {
        case selfClosing
        case closed
        case single
    }

    public let tag: String
    public let attributes: HTMLAttributes
    public let type: TagType
    public let content: String?
}

/// A class that processes a string and replace the designated shortcode for the replacement provided strings
///
open class HTMLProcessor: RegexProcessor {

    public typealias HTMLReplacer = (HTMLElement) -> String?

    let tag: String

    /// Regular expression to detect attributes
    /// Capture groups:
    ///
    /// 1. The element name
    /// 2. The element argument list
    /// 3. The self closing `/`
    /// 4. The content of a element when it wraps some content.
    /// 5. The closing tag.
    ///
    static func makeRegex(tag: String) -> NSRegularExpression {
        let pattern = "\\<(\(tag))(?![\\w-])([^\\>\\/]*(?:\\/(?!\\>)[^\\>\\/]*)*?)(?:(\\/)\\>|\\>(?:([^\\<]*(?:\\<(?!\\/\\1\\>)[^\\<]*)*)(\\<\\/\\1\\>))?)"
        let regex = try! NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        return regex
    }

    enum CaptureGroups: Int {
        case all = 0
        case name
        case arguments
        case selfClosingElement
        case content
        case closingTag

        static let allValues: [CaptureGroups] = [.all, .name, .arguments, .selfClosingElement, .content, .closingTag]
    }

    public init(tag: String, replacer: @escaping HTMLReplacer) {
        self.tag = tag
        let regex = HTMLProcessor.makeRegex(tag: tag)
        let regexReplacer = { (match: NSTextCheckingResult, text: String) -> String? in
            guard match.numberOfRanges == CaptureGroups.allValues.count else {
                return nil
            }
            var attributes = HTMLAttributes(named: [:], unamed: [])
            if let attributesText = match.captureGroup(in:CaptureGroups.arguments.rawValue, text: text) {
                attributes = HTMLAttributesParser.makeAttributes(in: attributesText)
            }

            var type: HTMLElement.TagType = .single
            if match.captureGroup(in:CaptureGroups.selfClosingElement.rawValue, text: text) != nil {
                type = .selfClosing
            } else if match.captureGroup(in:CaptureGroups.closingTag.rawValue, text: text) != nil {
                type = .closed
            }

            let content: String? = match.captureGroup(in:CaptureGroups.content.rawValue, text: text)

            let htmlElement = HTMLElement(tag: tag, attributes: attributes, type: type, content: content)
            return replacer(htmlElement)
        }

        super.init(regex: regex, replacer: regexReplacer)
    }
}
