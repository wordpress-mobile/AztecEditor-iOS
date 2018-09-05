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
    public let attributes: [ShortcodeAttribute]
    public let type: TagType
    public let content: String?
}

/// A class that processes a string and replace the designated shortcode for the replacement provided strings
///
open class HTMLProcessor: Processor {

    /// Whenever an HTML is found by the processor, this closure will be executed so that elements can be customized.
    ///
    public typealias Replacer = (HTMLElement) -> String?

    // MARK: - Basic Info
    
    let element: String
    
    // MARK: - Regex
    
    private enum CaptureGroups: Int {
        case all = 0
        case name
        case arguments
        case selfClosingElement
        case content
        case closingTag
        
        static let allValues: [CaptureGroups] = [.all, .name, .arguments, .selfClosingElement, .content, .closingTag]
    }
    
    /// Regular expression to detect attributes
    /// Capture groups:
    ///
    /// 1. The element name
    /// 2. The element argument list
    /// 3. The self closing `/`
    /// 4. The content of a element when it wraps some content.
    /// 5. The closing tag.
    ///
    private lazy var htmlRegexProcessor: RegexProcessor = { [unowned self] in
        let pattern = "\\<(\(element))(?![\\w-])([^\\>\\/]*(?:\\/(?!\\>)[^\\>\\/]*)*?)(?:(\\/)\\>|\\>(?:([^\\<]*(?:\\<(?!\\/\\1\\>)[^\\<]*)*)(\\<\\/\\1\\>))?)"
        let regex = try! NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        
        return RegexProcessor(regex: regex) { (match: NSTextCheckingResult, text: String) -> String? in
            return self.process(match: match, text: text)
        }
    }()
    
    // MARK: - Parsing & processing properties
    
    private let attributesParser = ShortcodeAttributeParser()
    private let replacer: Replacer
    
    // MARK: - Initializers
    
    public init(for element: String, replacer: @escaping Replacer) {
        self.element = element
        self.replacer = replacer
    }
        
    // MARK: - Processing

    public func process(_ text: String) -> String {
        return htmlRegexProcessor.process(text)
    }
}

// MARK: - Regex Match Processing Logic

private extension HTMLProcessor {
    /// Processes an HTML Element regex match.
    ///
    func process(match: NSTextCheckingResult, text: String) -> String? {
        
        guard match.numberOfRanges == CaptureGroups.allValues.count else {
            return nil
        }
        
        let attributes = self.attributes(from: match, in: text)
        let elementType = self.elementType(from: match, in: text)
        let content: String? = match.captureGroup(in: CaptureGroups.content.rawValue, text: text)
        
        let htmlElement = HTMLElement(tag: element, attributes: attributes, type: elementType, content: content)
        
        return replacer(htmlElement)
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
    private func elementType(from match: NSTextCheckingResult, in text: String) -> HTMLElement.TagType {
        if match.captureGroup(in: CaptureGroups.selfClosingElement.rawValue, text: text) != nil {
            return .selfClosing
        } else if match.captureGroup(in: CaptureGroups.closingTag.rawValue, text: text) != nil {
            return .closed
        }
        
        return .single
    }
}
