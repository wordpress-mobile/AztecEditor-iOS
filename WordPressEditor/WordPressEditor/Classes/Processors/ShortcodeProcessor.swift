import Aztec
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
    public let attributes: [ShortcodeAttribute]
    public let type: TagType
    public let content: String?
}

/// A class that processes a string and replace the designated shortcode for the replacement provided strings
///
public class ShortcodeProcessor: Processor {

    public typealias Replacer = (Shortcode) -> String?

    // MARK: - Basic Info
    
    let tag: String
    
    // MARK: - Regex
    
    private enum CaptureGroups: Int {
        case all = 0
        case extraOpen
        case name
        case arguments
        case selfClosingElement
        case content
        case closingTag
        case extraClose
        
        static let allValues = [.all, extraOpen, .name, .arguments, .selfClosingElement, .content, .closingTag, .extraClose]
    }

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
    private lazy var shortcodeRegexProcessor: RegexProcessor = { [unowned self] in
        let pattern = "\\[(\\[?)(\(tag))(?![\\w-])([^\\]\\/]*(?:\\/(?!\\])[^\\]\\/]*)*?)(?:(\\/)\\]|\\](?:([^\\[]*(?:\\[(?!\\/\\2\\])[^\\[]*)*)(\\[\\/\\2\\]))?)(\\]?)"
        let regex = try! NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        
        return RegexProcessor(regex: regex) { (match: NSTextCheckingResult, text: String) -> String? in
            return self.process(match: match, text: text)
        }
    }()
    
    // MARK: - Parsing & processing properties
    
    private let attributesParser = ShortcodeAttributeParser()
    private let replacer: Replacer

    // MARK: - Initializers
    
    public init(tag: String, replacer: @escaping Replacer) {
        self.tag = tag
        self.replacer = replacer
    }
    
    // MARK: - Processing
    
    public func process(_ text: String) -> String {
        return shortcodeRegexProcessor.process(text)
    }
}

private extension ShortcodeProcessor {
    
    func process(match: NSTextCheckingResult, text: String) -> String? {
        guard match.numberOfRanges == CaptureGroups.allValues.count else {
            return nil
        }
        
        let attributes = self.attributes(from: match, in: text)
        let elementType = self.elementType(from: match, in: text)
        let content: String? = match.captureGroup(in: CaptureGroups.content.rawValue, text: text)
        
        let shortcode = Shortcode(tag: tag, attributes: attributes, type: elementType, content: content)
        
        return replacer(shortcode)
    }
    
    // MARK: - Regex Match Processing Logic
    
    /// Obtains the attributes from an HTML element match.
    ///
    private func attributes(from match: NSTextCheckingResult, in text: String) -> [ShortcodeAttribute] {
        guard let attributesText = match.captureGroup(in: CaptureGroups.arguments.rawValue, text: text) else {
            return []
        }
        
        return attributesParser.parse(attributesText)
    }
    
    /// Obtains the element type for an HTML element match.
    ///
    private func elementType(from match: NSTextCheckingResult, in text: String) -> Shortcode.TagType {
        if match.captureGroup(in: CaptureGroups.selfClosingElement.rawValue, text: text) != nil {
            return .selfClosing
        } else if match.captureGroup(in: CaptureGroups.closingTag.rawValue, text: text) != nil {
            return .closed
        }
        
        return .single
    }
}
