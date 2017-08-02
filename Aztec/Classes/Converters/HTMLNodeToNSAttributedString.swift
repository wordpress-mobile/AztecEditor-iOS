import Foundation
import UIKit

class HTMLNodeToNSAttributedString: SafeConverter {

    /// The default font descriptor that will be used as a base for conversions.
    /// 
    let defaultFontDescriptor: UIFontDescriptor


    // MARK: - Initializers

    required init(usingDefaultFontDescriptor defaultFontDescriptor: UIFontDescriptor) {
        self.defaultFontDescriptor = defaultFontDescriptor
    }

    private lazy var defaultAttributes: [String: Any] = {
        let defaultFont = UIFont(descriptor: self.defaultFontDescriptor, size: self.defaultFontDescriptor.pointSize)
        return [NSFontAttributeName: defaultFont]
    }()


    // MARK: - Conversion

    /// Main conversion method.
    ///
    /// - Parameters:
    ///     - node: the node to convert to `NSAttributedString`.
    ///
    /// - Returns: the converted node as an `NSAttributedString`.
    ///
    func convert(_ node: Node) -> NSAttributedString {
        return convert(node, inheriting: defaultAttributes)
    }

    /// Recursive conversion method.  Useful for maintaining the font style of parent nodes when
    /// converting.
    ///
    /// - Parameters:
    ///     - node: the node to convert to `NSAttributedString`.
    ///     - attributes: the inherited attributes from parent nodes.
    ///
    /// - Returns: the converted node as an `NSAttributedString`.
    ///
    fileprivate func convert(_ node: Node, inheriting attributes: [String:Any]) -> NSAttributedString {
        switch node {
        case let textNode as TextNode:
            return convert(textNode, inheriting: attributes)
        case let commentNode as CommentNode:
            return convert(commentNode, inheriting: attributes)
        case let elementNode as ElementNode:
            return convert(elementNode, inheriting: attributes)
        default:
            fatalError("Nodes can be either text, comment or element nodes.")
        }
    }

    /// Converts a `TextNode` to `NSAttributedString`.
    ///
    /// - Parameters:
    ///     - node: the node to convert to `NSAttributedString`.
    ///     - attributes: the inherited attributes from parent nodes.
    ///
    /// - Returns: the converted node as an `NSAttributedString`.
    ///
    fileprivate func convert(_ node: TextNode, inheriting attributes: [String:Any]) -> NSAttributedString {

        let string: NSAttributedString

        if node.length() == 0 {
            string = NSAttributedString()
        } else {
            string = NSAttributedString(string: node.text(), attributes: attributes)
        }

        guard !node.needsClosingParagraphSeparator() else {
            return appendParagraphSeparator(to: string, inheriting: attributes)
        }

        return string
    }

    /// Converts a `CommentNode` to `NSAttributedString`.
    ///
    /// - Parameters:
    ///     - node: the node to convert to `NSAttributedString`.
    ///     - attributes: the inherited attributes from parent nodes.
    ///
    /// - Returns: the converted node as an `NSAttributedString`.
    ///
    fileprivate func convert(_ node: CommentNode, inheriting attributes: [String:Any]) -> NSAttributedString {
        let attachment = CommentAttachment()
        attachment.text = node.comment

        return NSAttributedString(attachment: attachment, attributes: attributes)
    }

    /// Converts an `ElementNode` to `NSAttributedString`.
    ///
    /// - Parameters:
    ///     - node: the node to convert to `NSAttributedString`.
    ///     - attributes: the inherited attributes from parent nodes.
    ///
    /// - Returns: the converted node as an `NSAttributedString`.
    ///
    fileprivate func convert(_ element: ElementNode, inheriting attributes: [String: Any]) -> NSAttributedString {

        guard element.isSupportedByEditor() else {
            return convert(unsupported: element, inheriting: attributes)
        }

        let childAttributes = self.attributes(for: element, inheriting: attributes)
        let content = NSMutableAttributedString()

        if let representation = implicitRepresentation(for: element, inheriting: childAttributes) {
            content.append(representation)
        } else {
            for child in element.children {
                let childContent = convert(child, inheriting: childAttributes)
                content.append(childContent)
            }
        }

        guard !element.needsClosingParagraphSeparator() else {
            return appendParagraphSeparator(to: content, inheriting: childAttributes)
        }

        return content
    }

    fileprivate func convert(unsupported element: ElementNode, inheriting attributes: [String:Any]) -> NSAttributedString {
        let converter = OutHTMLConverter()
        let attachment = HTMLAttachment()

        attachment.rootTagName = element.name
        attachment.rawHTML = converter.convert(element)

        return NSAttributedString(attachment: attachment, attributes: attributes)
    }

    // MARK: - Paragraph Separator

    private func appendParagraphSeparator(to string: NSAttributedString, inheriting inheritedAttributes: [String: Any]) -> NSAttributedString {

        let stringWithSeparator = NSMutableAttributedString(attributedString: string)

        stringWithSeparator.append(NSAttributedString(.paragraphSeparator, attributes: inheritedAttributes))

        return NSAttributedString(attributedString: stringWithSeparator)
    }


    // MARK: - Node Styling

    public let elementToFormattersMap: [StandardElementType: AttributeFormatter] = [
        .ol: TextListFormatter(style: .ordered, increaseDepth: true),
        .ul: TextListFormatter(style: .unordered, increaseDepth: true),
        .blockquote: BlockquoteFormatter(),
        .div: HTMLDivFormatter(),
        .strong: BoldFormatter(),
        .em: ItalicFormatter(),
        .u: UnderlineFormatter(),
        .del: StrikethroughFormatter(),
        .a: LinkFormatter(),
        .img: ImageFormatter(),
        .hr: HRFormatter(),
        .h1: HeaderFormatter(headerLevel: .h1),
        .h2: HeaderFormatter(headerLevel: .h2),
        .h3: HeaderFormatter(headerLevel: .h3),
        .h4: HeaderFormatter(headerLevel: .h4),
        .h5: HeaderFormatter(headerLevel: .h5),
        .h6: HeaderFormatter(headerLevel: .h6),
        .p: HTMLParagraphFormatter(),
        .pre: PreFormatter(),
        .video: VideoFormatter()
    ]

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

private extension HTMLNodeToNSAttributedString {

    // MARK: - NSAttributedString attribute generation

    /// Calculates the attributes for the specified node.  Returns a dictionary including inherited
    /// attributes.
    ///
    /// - Parameters:
    ///     - node: the node to get the information from.
    ///
    /// - Returns: an attributes dictionary, for use in an NSAttributedString.
    ///
    func attributes(for element: ElementNode, inheriting attributes: [String: Any]) -> [String: Any] {

        guard !(element is RootNode) else {
            return attributes
        }

        let elementRepresentation = HTMLElementRepresentation(element)
        let representation = HTMLRepresentation(for: .element(elementRepresentation))
        var finalAttributes = attributes

        if let elementFormatter = formatter(for: element) {
            finalAttributes = elementFormatter.apply(to: finalAttributes, andStore: representation)
        } else if element.name == StandardElementType.li.rawValue {
            // ^ Since LI is handled by the OL and UL formatters, we can safely ignore it here.
            finalAttributes = attributes
        } else {
            finalAttributes = self.attributes(storing: elementRepresentation, in: finalAttributes)
        }

        for attribute in element.attributes {
            finalAttributes = self.stringAttributes(for: attribute, inheriting: finalAttributes)
        }
        
        return finalAttributes
    }


    /// Calculates the string attributes for the specified HTML attribute.  Returns a dictionary
    /// including inherited attributes.
    ///
    /// - Parameters:
    ///     - attributeRepresentation: the element representation.
    ///     - inheritedAttributes: the attributes that will be inherited.
    ///
    /// - Returns: an attributes dictionary, for use in an NSAttributedString.
    ///
    private func stringAttributes(for attribute: Attribute, inheriting inheritedAttributes: [String: Any]) -> [String: Any] {

        let attributes: [String:Any]

        if let attributeFormatter = formatter(for: attribute) {
            let attributeHTMLRepresentation = HTMLRepresentation(for: .attribute(attribute))

            attributes = attributeFormatter.apply(to: inheritedAttributes, andStore: attributeHTMLRepresentation)
        } else {
            attributes = inheritedAttributes
        }
        
        return attributes
    }


    /// Stores the specified HTMLElementRepresentation in a collection of NSAttributedString Attributes.
    ///
    /// - Parameters:
    ///     - elementRepresentation: Instance of HTMLElementRepresentation to be stored.
    ///     - attributes: Attributes where we should store the HTML Representation.
    ///
    /// - Returns: A collection of NSAttributedString Attributes, including the specified HTMLElementRepresentation.
    ///
    private func attributes(storing representation: HTMLElementRepresentation, in attributes: [String: Any]) -> [String: Any] {
        let unsupportedHTML = attributes[UnsupportedHTMLAttributeName] as? UnsupportedHTML
        var representations = unsupportedHTML?.representations ?? []
        representations.append(representation)

        // Note:
        // We'll *ALWAYS* store a copy of the UnsupportedHTML instance. Reason is: reusing the old instance
        // would mean affecting a range that may fall beyond what we expected!
        //
        var updated = attributes
        updated[UnsupportedHTMLAttributeName] = UnsupportedHTML(representations: representations)

        return updated
    }
}

extension HTMLNodeToNSAttributedString {

    // MARK: - Formatters

    func formatter(for attribute: Attribute) -> AttributeFormatter? {
        // TODO: implement attribute representation formatters
        //
        return nil
    }

    func formatter(for element: ElementNode) -> AttributeFormatter? {

        guard let standardType = element.standardName else {
            return nil
        }

        let equivalentNames = standardType.equivalentNames

        for (key, formatter) in elementToFormattersMap {
            if equivalentNames.contains(key.rawValue) {
                return formatter
            }
        }

        return nil
    }
}

private extension HTMLNodeToNSAttributedString {

    // MARK: - Implicit Representations

    /// Some elements have an implicit representation that doesn't really follow the standard
    /// conversion logic.  This method takes care of such specialized conversions.
    ///
    /// - Parameters:
    ///     - element: the element to request an implicit representation for.
    ///     - attributes: the attributes that the output attributed string will inherit.
    ///
    /// - Returns: the requested implicit representation, if one exists, or `nil`.
    ///
    func implicitRepresentation(for element: ElementNode, inheriting attributes: [String:Any]) -> NSAttributedString? {

        guard let elementType = element.standardName else {
            return nil
        }

        return implicitRepresentation(for: elementType, inheriting: attributes)
    }

    /// Some element types have an implicit representation that doesn't really follow the standard
    /// conversion logic.  This method takes care of such specialized conversions.
    ///
    /// - Parameters:
    ///     - elementType: the element type to request an implicit representation for.
    ///     - attributes: the attributes that the output attributed string will inherit.
    ///
    /// - Returns: the requested implicit representation, if one exists, or `nil`.
    ///
    private func implicitRepresentation(for elementType: StandardElementType, inheriting attributes: [String:Any]) -> NSAttributedString? {

        switch elementType {
        case .hr, .img, .video:
            return NSAttributedString(string: String(UnicodeScalar(NSAttachmentCharacter)!), attributes: attributes)
        case .br:
            return NSAttributedString(.lineSeparator, attributes: attributes)
        default:
            return nil
        }
    }

}
