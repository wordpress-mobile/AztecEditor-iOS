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

        if let nodeType = element.standardName,
            let implicitRepresentation = nodeType.implicitRepresentation(withAttributes: childAttributes) {

            content.append(implicitRepresentation)
        } else {
            for child in element.children {
                let childContent = convert(child, inheriting: childAttributes)
                content.append(childContent)
            }
        }

        guard !element.needsClosingParagraphSeparator() else {
            return appendParagraphSeparator(to: content, inheriting: attributes)
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

    /// Returns an attributed string representing the specified node.
    ///
    /// - Parameters:
    ///     - node: the element node to generate a representation string of.
    ///     - attributes: the inherited attributes from parent nodes.
    ///
    /// - Returns: the attributed string representing the specified element node.
    ///
    ///
    fileprivate func string(for element: ElementNode, inheriting attributes: [String:Any]) -> NSAttributedString {
        
        let childAttributes = self.attributes(for: element, inheriting: attributes)
        let content = NSMutableAttributedString()

        if let nodeType = element.standardName,
            let implicitRepresentation = nodeType.implicitRepresentation(withAttributes: childAttributes) {

            content.append(implicitRepresentation)
        } else {
            for child in element.children {
                let childContent = convert(child, inheriting: childAttributes)
                content.append(childContent)
            }
        }

        guard !element.needsClosingParagraphSeparator() else {
            return appendParagraphSeparator(to: content, inheriting: attributes)
        }
        
        return content
    }

    public let elementToFormattersMap: [StandardElementType: AttributeFormatter] = [
        .ol: TextListFormatter(style: .ordered, increaseDepth: true),
        .ul: TextListFormatter(style: .unordered, increaseDepth: true),
        .blockquote: BlockquoteFormatter(),
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

    let attributesToFormattersMap: [StandardHTMLAttribute: AttributeFormatter] = [
    ]

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

        let representation = HTMLRepresentation.element(element)
        var finalAttributes = attributes

        if let elementFormatter = formatter(for: element) {
            finalAttributes = elementFormatter.apply(to: finalAttributes, andStore: representation)
        } else  if element.name == StandardElementType.li.rawValue {
            // ^ Since LI is handled by the OL and UL formatters, we can safely ignore it here.

            finalAttributes = attributes
        } else {
            finalAttributes = self.attributes(storing: element, in: finalAttributes)
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
            let attributeHTMLRepresentation = HTMLRepresentation.attribute(attribute)

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
    private func attributes(storing element: ElementNode, in attributes: [String: Any]) -> [String: Any] {
        let unsupportedHTML = attributes[UnsupportedHTMLAttributeName] as? UnsupportedHTML ?? UnsupportedHTML()
        unsupportedHTML.add(element: element)

        var updated = attributes
        updated[UnsupportedHTMLAttributeName] = unsupportedHTML

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
