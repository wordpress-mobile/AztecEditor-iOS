import Foundation
import Gridicons
import UIKit

class HTMLNodeToNSAttributedString: SafeConverter {

    typealias ElementNode = Libxml2.ElementNode
    typealias Node = Libxml2.Node
    typealias RootNode = Libxml2.RootNode
    typealias StringAttribute = Libxml2.StringAttribute
    typealias TextNode = Libxml2.TextNode
    typealias CommentNode = Libxml2.CommentNode
    typealias StandardElementType = Libxml2.StandardElementType

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

        let string = convertContents(of: node, inheriting: attributes)

        guard node.needsClosingParagraphSeparator() else {
            return string
        }

        return appendParagraphSeparator(to: string, inheriting: attributes)
    }

    private func convertContents(of node: Node, inheriting attributes: [String:Any]) -> NSAttributedString {
        switch node {
        case let textNode as TextNode:
            return convertTextNode(textNode, inheriting: attributes)
        case let commentNode as CommentNode:
            return convertCommentNode(commentNode, inheriting: attributes)
        case let elementNode as ElementNode:
            return convertElementNode(elementNode, inheriting: attributes)
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
    fileprivate func convertTextNode(_ node: TextNode, inheriting attributes: [String:Any]) -> NSAttributedString {
        guard node.length() > 0 else {
            return NSAttributedString()
        }

        return NSAttributedString(string: node.text(), attributes: attributes)
    }

    /// Converts a `CommentNode` to `NSAttributedString`.
    ///
    /// - Parameters:
    ///     - node: the node to convert to `NSAttributedString`.
    ///     - attributes: the inherited attributes from parent nodes.
    ///
    /// - Returns: the converted node as an `NSAttributedString`.
    ///
    fileprivate func convertCommentNode(_ node: CommentNode, inheriting attributes: [String:Any]) -> NSAttributedString {
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
    fileprivate func convertElementNode(_ node: ElementNode, inheriting attributes: [String: Any]) -> NSAttributedString {
        guard !node.isSupportedByEditor() else {
            return stringForNode(node, inheriting: attributes)
        }

        let converter = Libxml2.Out.HTMLConverter()
        let attachment = HTMLAttachment()

        attachment.rootTagName = node.name
        attachment.rawHTML = converter.convert(node)

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
    fileprivate func stringForNode(_ node: ElementNode, inheriting attributes: [String:Any]) -> NSAttributedString {
        
        let childAttributes = self.attributes(forNode: node, inheriting: attributes)
        
        if let nodeType = node.standardName,
            let implicitRepresentation = nodeType.implicitRepresentation(withAttributes: childAttributes) {
            
            return implicitRepresentation
        }

        let content = NSMutableAttributedString()
        
        for child in node.children {
            let childContent = convert(child, inheriting: childAttributes)
            content.append(childContent)
        }
        
        return content
    }

/*
        var attributes = inheritedAttributes
        let attributeValue = parseCustomAttributeValues(forNode: node)

        for (key, formatter) in elementToFormattersMap {
            if node.isNodeType(key) {
                if let standardValueFormatter = formatter as? StandardAttributeFormatter,
                    let value = attributeValue {
                    standardValueFormatter.attributeValue = value
                }
                attributes = formatter.apply(to: attributes);
            }
        }

        if let elementStyle = node.valueForStringAttribute(named: "style") {
            let styles = parseStyle(style: elementStyle)
            for (key, (formatter, parser)) in styleToFormattersMap {
                guard let styleString = styles[key],
                      let standardValueFormatter = formatter as? StandardAttributeFormatter,
                      let value = parser(styleString)
                    else {
                        continue
                    }
                    standardValueFormatter.attributeValue = value
                    attributes = standardValueFormatter.apply(to: attributes);
            }
        }
        return attributes
    }

    public func parseCustomAttributeValues(forNode node: ElementNode) -> Any? {

        var attributeValue: Any?

        if node.isNodeType(.a) {
            var linkURL: URL?

            if let attributeIndex = node.attributes.index(where: { $0.name == HTMLLinkAttribute.Href.rawValue }),
                let attribute = node.attributes[attributeIndex] as? StringAttribute {

                linkURL = URL(string: attribute.value)
            } else {
                // We got a link tag without an HREF attribute
                //
                linkURL = URL(string: "")
            }

            attributeValue = linkURL
        }

        if node.isNodeType(.img) {
            let url: URL?

            if let urlString = node.valueForStringAttribute(named: "src") {
                url = URL(string: urlString)
            } else {
                url = nil
            }

            let attachment = ImageAttachment(identifier: UUID().uuidString, url: url)

            if let elementClass = node.valueForStringAttribute(named: "class") {
                let classAttributes = elementClass.components(separatedBy: " ")
                for classAttribute in classAttributes {
                    if let alignment = ImageAttachment.Alignment.fromHTML(string: classAttribute) {
                        attachment.alignment = alignment
                    }
                    if let size = ImageAttachment.Size.fromHTML(string: classAttribute) {
                        attachment.size = size
                    }
                }
            }
            attributeValue = attachment
        }

        if node.isNodeType(.video) {

            var namedAttributes = node.namedAttributes
            var srcURL: URL?
            if let urlString = namedAttributes["src"] {
                srcURL = URL(string: urlString)
                namedAttributes.removeValue(forKey: "src")
            }

            var posterURL: URL?
            if let urlString = namedAttributes["poster"] {
                posterURL = URL(string: urlString)
                namedAttributes.removeValue(forKey: "poster")
            }

            let attachment = VideoAttachment(identifier: UUID().uuidString, srcURL: srcURL, posterURL: posterURL, namedAttributes: namedAttributes, unnamedAttributes: node.unnamedAttributes)

            attributeValue = attachment
        }

        return attributeValue
    }
 */

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
    func attributes(forNode node: ElementNode, inheriting attributes: [String: Any]) -> [String: Any] {

        guard !(node is RootNode) else {
            return attributes
        }

        let elementRepresentation = HTMLElementRepresentation(for: node)
        return self.attributes(for: elementRepresentation, inheriting: attributes)
    }

    /// Calculates the attributes for the specified element representation.  Returns a dictionary
    /// including inherited attributes.
    ///
    /// - Parameters:
    ///     - elementRepresentation: the element representation.
    ///     - inheritedAttributes: the attributes that will be inherited.
    ///
    /// - Returns: an attributes dictionary, for use in an NSAttributedString.
    ///
    private func attributes(for elementRepresentation: HTMLElementRepresentation, inheriting attributes: [String: Any]) -> [String: Any] {

        var finalAttributes = attributes

        if let elementFormatter = formatter(for: elementRepresentation) {
            finalAttributes = elementFormatter.apply(to: finalAttributes, andStore: elementRepresentation)
        } else {
            finalAttributes = self.attributes(storing: elementRepresentation, in: finalAttributes)
        }

        for attributeRepresentation in elementRepresentation.attributes {
            finalAttributes = self.attributes(for: attributeRepresentation, inheriting: finalAttributes)
        }

        return finalAttributes
    }


    /// Calculates the attributes for the specified element representation.  Returns a dictionary
    /// including inherited attributes.
    ///
    /// - Parameters:
    ///     - attributeRepresentation: the element representation.
    ///     - inheritedAttributes: the attributes that will be inherited.
    ///
    /// - Returns: an attributes dictionary, for use in an NSAttributedString.
    ///
    private func attributes(for attributeRepresentation: HTMLAttributeRepresentation, inheriting inheritedAttributes: [String: Any]) -> [String: Any] {

        let attributes: [String:Any]

        if let attributeFormatter = formatter(for: attributeRepresentation) {
            attributes = attributeFormatter.apply(to: inheritedAttributes, andStore: attributeRepresentation)
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
    private func attributes(storing elementRepresentation: HTMLElementRepresentation, in attributes: [String: Any]) -> [String: Any] {
        let unsupportedHTML = attributes[UnsupportedHTMLAttributeName] as? UnsupportedHTML ?? UnsupportedHTML()
        unsupportedHTML.add(element: elementRepresentation)

        var updated = attributes
        updated[UnsupportedHTMLAttributeName] = unsupportedHTML

        return updated
    }
}

extension HTMLNodeToNSAttributedString {

    // MARK: - Formatters

    func formatter(for representation: HTMLAttributeRepresentation) -> AttributeFormatter? {
        // TODO: implement attribute representation formatters
        //
        return nil
    }

    func formatter(for representation: HTMLElementRepresentation) -> AttributeFormatter? {

        guard let standardType = StandardElementType(rawValue: representation.name) else {
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
