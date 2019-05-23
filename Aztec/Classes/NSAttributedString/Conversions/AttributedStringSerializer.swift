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
        .cite: CiteElementConverter(),
        .figcaption: FigcaptionElementConverter(),
        .figure: FigureElementConverter(),
        .hr: HRElementConverter(),
        .img: ImageElementConverter(),
        .video: VideoElementConverter(),
        .li: LIElementConverter()
    ]
    
    // MARK: - Attributes Converter
    
    let attributesConverter = MainAttributesConverter([
        BoldElementAttributesConverter(),
        ItalicElementAttributesConverter(),
        UnderlineElementAttributesConverter(),
        ]
    )
    
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
    func serialize(_ node: Node, defaultAttributes: [NSAttributedString.Key: Any] = [:]) -> NSAttributedString {
        return serialize(node, inheriting: defaultAttributes)
    }

    /// Recursive serialization method.
    ///
    /// - Parameters:
    ///     - node: the node to convert to `NSAttributedString`.
    ///     - attributes: the inherited attributes from parent nodes.
    ///
    /// - Returns: the converted node as an `NSAttributedString`.
    ///
    func serialize(_ node: Node, inheriting attributes: [NSAttributedString.Key: Any]) -> NSAttributedString {
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
    fileprivate func serialize(_ node: TextNode, inheriting attributes: [NSAttributedString.Key: Any]) -> NSAttributedString {

        let text = node.sanitizedText()
        
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
    fileprivate func serialize(_ node: CommentNode, inheriting attributes: [NSAttributedString.Key: Any]) -> NSAttributedString {
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
    fileprivate func serialize(_ element: ElementNode, inheriting attributes: [NSAttributedString.Key: Any]) -> NSAttributedString {

        let content = NSMutableAttributedString()
        let attributes = attributesConverter.convert(element.attributes, inheriting: attributes)
        
        let converter = self.converter(for: element)
        let convertedString = converter.convert(element, inheriting: attributes, contentSerializer: contentSerializer)
        
        content.append(convertedString)

        return content
    }

    // MARK: - Paragraph Separator

    private func appendParagraphSeparator(to string: NSAttributedString, inheriting inheritedAttributes: [NSAttributedString.Key: Any]) -> NSAttributedString {

        let stringWithSeparator = NSMutableAttributedString(attributedString: string)

        stringWithSeparator.append(NSAttributedString(.paragraphSeparator, attributes: inheritedAttributes))

        return NSAttributedString(attributedString: stringWithSeparator)
    }

    // MARK: - Built-in element converter instances

    // This converter should not be added to `elementFormattersMap`.  This converter is returned
    // whenever the map doesn't find a proper match.
    //
    private(set) lazy var genericElementConverter = GenericElementConverter()
    
    lazy var contentSerializer: ElementConverter.ContentSerializer = { [unowned self] (elementNode, intrinsicRepresentation, attributes, intrinsicRepresentationBeforeChildren) in
        let content = NSMutableAttributedString()

        if let intrinsicRepresentation = intrinsicRepresentation, intrinsicRepresentationBeforeChildren {
            content.append(intrinsicRepresentation)
        }

        for child in elementNode.children {
            let nodeString = self.serialize(child, inheriting: attributes)
            content.append(nodeString)
        }
        
        if let intrinsicRepresentation = intrinsicRepresentation, !intrinsicRepresentationBeforeChildren {
            content.append(intrinsicRepresentation)
        }
        
        guard !elementNode.needsClosingParagraphSeparator() else {
            return self.appendParagraphSeparator(to: content, inheriting: attributes)
        }
        
        return content
    }

    // MARK: - Formatter Maps

    public lazy var attributeFormattersMap: [String: AttributeFormatter] = {
        return [:]
    }()

    public let styleToFormattersMap: [String: (AttributeFormatter, (String)->Any?)] = [
        "color": (ColorFormatter(), {(value) in return UIColor(hexString: value)}),
        "text-decoration": (UnderlineFormatter(), { (value) in return value == "underline" ? NSUnderlineStyle.single.rawValue : nil})
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
