import Foundation
import UIKit

protocol AttributedStringSerializerCustomizer {
    func converter(for: ElementNode) -> ElementConverter?
}

/// Composes an attributed string from an HTML tree.
///
class AttributedStringSerializer {
    private let customizer: AttributedStringSerializerCustomizer?
    
    // MARK: - Element Converters
    
    private static let defaultElementConverters: [Element: ElementConverter] = [
        .br: BRElementConverter(),
        .figcaption: FigcaptionElementConverter(),
        .figure: FigureElementConverter(),
        .hr: HRElementConverter(),
        .img: ImageElementConverter(),
        .video: VideoElementConverter()
    ]
    
    // MARK: - Initializers

    required init(
        customizer: AttributedStringSerializerCustomizer? = nil) {
        
        self.customizer = customizer
    }

    // MARK: - Conversion

    /// Serializes an attributed string with the specified node hierarchy.
    ///
    /// - Parameters:
    ///     - node: the head of the tree to compose into an attributed string.
    ///
    /// - Returns: the requested attributed string.
    ///
    func serialize(_ node: Node, defaultAttributes: [NSAttributedStringKey: Any] = [:]) -> NSAttributedString {
        return serialize(node, inheriting: defaultAttributes)
    }

    /// Recursive serialization method.  Useful for maintaining the font style of parent nodes.
    ///
    /// - Parameters:
    ///     - node: the node to convert to `NSAttributedString`.
    ///     - attributes: the inherited attributes from parent nodes.
    ///
    /// - Returns: the converted node as an `NSAttributedString`.
    ///
    func serialize(_ node: Node, inheriting attributes: [NSAttributedStringKey: Any]) -> NSAttributedString {
        switch node {
        case let textNode as TextNode:
            return serialize(textNode, inheriting: attributes)
        case let commentNode as CommentNode:
            return serialize(commentNode, inheriting: attributes)
        case let elementNode as ElementNode:
            return serialize(elementNode, inheriting: attributes)
        default:
            fatalError("Nodes can be either text, comment or element nodes.")
        }
    }

    /// Serializes a `TextNode`.
    ///
    /// - Parameters:
    ///     - node: the node to convert to `NSAttributedString`.
    ///     - attributes: the inherited attributes from parent nodes.
    ///
    /// - Returns: the converted node as an `NSAttributedString`.
    ///
    fileprivate func serialize(_ node: TextNode, inheriting attributes: [NSAttributedStringKey: Any]) -> NSAttributedString {

        let text = sanitizeText(from: node)
        
        guard text.count > 0 else {
            return NSAttributedString()
        }
        
        let string = NSAttributedString(string: text, attributes: attributes)

        guard !node.needsClosingParagraphSeparator() else {
            return appendParagraphSeparator(to: string, inheriting: attributes)
        }

        return string
    }

    /// Serializes a `CommentNode`.
    ///
    /// - Parameters:
    ///     - node: the node to convert to `NSAttributedString`.
    ///     - attributes: the inherited attributes from parent nodes.
    ///
    /// - Returns: the converted node as an `NSAttributedString`.
    ///
    fileprivate func serialize(_ node: CommentNode, inheriting attributes: [NSAttributedStringKey: Any]) -> NSAttributedString {
        let attachment = CommentAttachment()
        attachment.text = node.comment

        let content = NSMutableAttributedString(attachment: attachment, attributes: attributes)
        
        guard !node.needsClosingParagraphSeparator() else {
            return appendParagraphSeparator(to: content, inheriting: attributes)
        }
        
        return content
    }

    /// Serializes an `ElementNode`.
    ///
    /// - Parameters:
    ///     - element: the node to convert to `NSAttributedString`.
    ///     - attributes: the inherited attributes from parent nodes.
    ///
    /// - Returns: the converted node as an `NSAttributedString`.
    ///
    fileprivate func serialize(_ element: ElementNode, inheriting attributes: [NSAttributedStringKey: Any]) -> NSAttributedString {

        let content = NSMutableAttributedString()

        let converter = self.converter(for: element)
        let convertedString = converter.convert(element, inheriting: attributes, childrenSerializer: childrenSerializer)
        
        content.append(convertedString)
        
        guard !element.needsClosingParagraphSeparator() else {
            return appendParagraphSeparator(to: content, inheriting: attributes)
        }

        return content
    }

    // MARK: - Paragraph Separator

    private func appendParagraphSeparator(to string: NSAttributedString, inheriting inheritedAttributes: [NSAttributedStringKey: Any]) -> NSAttributedString {

        let stringWithSeparator = NSMutableAttributedString(attributedString: string)

        stringWithSeparator.append(NSAttributedString(.paragraphSeparator, attributes: inheritedAttributes))

        return NSAttributedString(attributedString: stringWithSeparator)
    }

    // MARK: - Built-in element converter instances

    // This converter should not be added to `elementFormattersMap`.  This converter is returned
    // whenever the map doesn't find a proper match.
    //
    private(set) lazy var genericElementConverter = GenericElementConverter()
    
    lazy var childrenSerializer: ElementConverter.ChildrenSerializer = { [weak self] (children, attributes) in
        let content = NSMutableAttributedString()
        
        guard let `self` = self else {
            return content
        }
        
        for child in children {
            let nodeString = self.serialize(child, inheriting: attributes)
            content.append(nodeString)
        }
        
        return content
    }

    // MARK: - Formatter Maps

    public lazy var attributeFormattersMap: [String: AttributeFormatter] = {
        return [:]
    }()

    let attributesToFormattersMap: [StandardHTMLAttribute: AttributeFormatter] = [:]

    public let styleToFormattersMap: [String: (AttributeFormatter, (String)->Any?)] = [
        "color": (ColorFormatter(), {(value) in return UIColor(hexString: value)}),
        "text-decoration": (UnderlineFormatter(), { (value) in return value == "underline" ? NSUnderlineStyle.styleSingle.rawValue : nil})
    ]

    func parseStyle(style: String) -> [String: String] {
        var stylesDictionary = [String: String]()
        let styleAttributes = style.components(separatedBy: ";")
        for sytleAttribute in styleAttributes {
            let keyValue = sytleAttribute.components(separatedBy: ":")
            guard keyValue.count == 2,
                  let key = keyValue.first?.trimmingCharacters(in: CharacterSet.whitespaces),
                  let value = keyValue.last?.trimmingCharacters(in: CharacterSet.whitespaces) else {
                continue
            }
            stylesDictionary[key] = value
        }
        return stylesDictionary
    }
}

private extension AttributedStringSerializer {

    // MARK: - Element Converters

    /// Some element types have an implicit representation that doesn't really follow the standard conversion logic.
    /// Element Converters take care of that.
    ///
    func converter(for element: ElementNode) -> ElementConverter {
        if let converter = customizer?.converter(for: element) {
            return converter
        }
        
        return AttributedStringSerializer.defaultElementConverters[element.type] ?? genericElementConverter
    }
}


// MARK: - Text Sanitization for Rendering

private extension AttributedStringSerializer {
    
    func sanitizeText(from textNode: TextNode) -> String {
        if textNode.hasAncestor(ofType: .pre) {
            return preSanitize(textNode.text())
        } else {
            return sanitize(textNode.text())
        }
    }
    
    /// This method check that in the current context it makes sense to clean up newlines and double spaces from text.
    /// For example if you are inside a pre element you shoulnd't clean up the nodes.
    ///
    /// - Parameter rawNode: the base node to check
    ///
    /// - Returns: true if sanitization should happen, false otherwise
    ///
    private func shouldSanitizeText(for textNode: TextNode) -> Bool {
        return !textNode.hasAncestor(ofType: .pre)
    }

    private func preSanitize(_ text:String) -> String {
        var result =  text.replacingOccurrences(of: String(.paragraphSeparator), with: String(.lineSeparator))
        result = text.replacingOccurrences(of: "\n", with: String(.lineSeparator))
        return result
    }

    private func sanitize(_ text: String) -> String {
        let hasAnEndingSpace = text.hasSuffix(String(.space))
        let hasAStartingSpace = text.hasPrefix(String(.space))
        
        // We cannot use CharacterSet.whitespacesAndNewlines directly, because it includes
        // U+000A, which is non-breaking space.  We need to maintain it.
        //
        let whitespace = CharacterSet.whitespacesAndNewlines
        let whitespaceToKeep = CharacterSet(charactersIn: String(.nonBreakingSpace))
        let whitespaceToRemove = whitespace.subtracting(whitespaceToKeep)
        
        let trimmedText = text.trimmingCharacters(in: whitespaceToRemove)
        var singleSpaceText = trimmedText
        let doubleSpace = "  "
        let singleSpace = " "
        
        while singleSpaceText.range(of: doubleSpace) != nil {
            singleSpaceText = singleSpaceText.replacingOccurrences(of: doubleSpace, with: singleSpace)
        }
        
        let noBreaksText = singleSpaceText.replacingOccurrences(of: String(.lineFeed), with: "")
        let endingSpace = !noBreaksText.isEmpty && hasAnEndingSpace ? String(.space) : ""
        let startingSpace = !noBreaksText.isEmpty && hasAStartingSpace ? String(.space) : ""
        return "\(startingSpace)\(noBreaksText)\(endingSpace)"
    }
}
