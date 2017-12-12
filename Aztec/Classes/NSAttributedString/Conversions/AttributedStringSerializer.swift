import Foundation
import UIKit

/// Composes an attributed string from an HTML tree.
///
class AttributedStringSerializer {

    private let defaultAttributes: [AttributedStringKey: Any]

    // MARK: - Initializers

    required init(defaultAttributes: [AttributedStringKey: Any]) {
        self.defaultAttributes = defaultAttributes
    }


    // MARK: - Conversion

    /// Serializes an attributed string with the specified node hierarchy.
    ///
    /// - Parameters:
    ///     - node: the head of the tree to compose into an attributed string.
    ///
    /// - Returns: the requested attributed string.
    ///
    func serialize(_ node: Node) -> NSAttributedString {
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
    fileprivate func serialize(_ node: Node, inheriting attributes: [AttributedStringKey: Any]) -> NSAttributedString {
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
    fileprivate func serialize(_ node: TextNode, inheriting attributes: [AttributedStringKey: Any]) -> NSAttributedString {

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
    fileprivate func serialize(_ node: CommentNode, inheriting attributes: [AttributedStringKey: Any]) -> NSAttributedString {
        let attachment = CommentAttachment()
        attachment.text = node.comment

        return NSAttributedString(attachment: attachment, attributes: attributes)
    }

    /// Serializes an `ElementNode`.
    ///
    /// - Parameters:
    ///     - element: the node to convert to `NSAttributedString`.
    ///     - attributes: the inherited attributes from parent nodes.
    ///
    /// - Returns: the converted node as an `NSAttributedString`.
    ///
    fileprivate func serialize(_ element: ElementNode, inheriting attributes: [AttributedStringKey: Any]) -> NSAttributedString {

        guard element.isSupportedByEditor() else {
            return serialize(unsupported: element, inheriting: attributes)
        }

        let childAttributes = self.attributes(for: element, inheriting: attributes)
        let content = NSMutableAttributedString()

        if let converter = converter(for: element) {
            let convertedString = converter.convert(from: element, inheritedAttributes: childAttributes)
            content.append(convertedString)
        } else {
            for child in element.children {
                let childContent = serialize(child, inheriting: childAttributes)
                content.append(childContent)
            }
        }

        guard !element.needsClosingParagraphSeparator() else {
            return appendParagraphSeparator(to: content, inheriting: childAttributes)
        }

        return content
    }

    /// - Parameters:
    ///     - element: the node to convert to `NSAttributedString`.
    ///     - attributes: the inherited attributes from parent nodes.
    ///
    /// - Returns: the converted node as an `NSAttributedString`.
    ///
    fileprivate func serialize(unsupported element: ElementNode, inheriting attributes: [AttributedStringKey: Any]) -> NSAttributedString {
        let serializer = DefaultHTMLSerializer()
        let attachment = HTMLAttachment()

        attachment.rootTagName = element.name
        attachment.rawHTML = serializer.serialize(element)

        return NSAttributedString(attachment: attachment, attributes: attributes)
    }

    // MARK: - Paragraph Separator

    private func appendParagraphSeparator(to string: NSAttributedString, inheriting inheritedAttributes: [AttributedStringKey: Any]) -> NSAttributedString {

        let stringWithSeparator = NSMutableAttributedString(attributedString: string)

        stringWithSeparator.append(NSAttributedString(.paragraphSeparator, attributes: inheritedAttributes))

        return NSAttributedString(attributedString: stringWithSeparator)
    }

    // MARK: - Built-in formatter instances

    let blockquoteFormatter = BlockquoteFormatter()
    let boldFormatter = BoldFormatter()
    let divFormatter = HTMLDivFormatter()
    let h1Formatter = HeaderFormatter(headerLevel: .h1)
    let h2Formatter = HeaderFormatter(headerLevel: .h2)
    let h3Formatter = HeaderFormatter(headerLevel: .h3)
    let h4Formatter = HeaderFormatter(headerLevel: .h4)
    let h5Formatter = HeaderFormatter(headerLevel: .h5)
    let h6Formatter = HeaderFormatter(headerLevel: .h6)
    let italicFormatter = ItalicFormatter()
    let linkFormatter = LinkFormatter()
    let orderedListFormatter = TextListFormatter(style: .ordered, increaseDepth: true)
    let paragraphFormatter = HTMLParagraphFormatter()
    let preFormatter = PreFormatter()
    let strikethroughFormatter = StrikethroughFormatter()
    let underlineFormatter = UnderlineFormatter()
    let unorderedListFormatter = TextListFormatter(style: .unordered, increaseDepth: true)

    // MARK: - Built-in element converter instances

    let brElementConverter = BRElementConverter()
    let figureElementConverter = FigureElementConverter()
    let hrElementConverter = HRElementConverter()
    let imageElementConverter = ImageElementConverter()
    let videoElementConverter = VideoElementConverter()

    // MARK: - Formatter Maps

    public lazy var attributeFormattersMap: [String: AttributeFormatter] = {
        return [:]
    }()

    public lazy var elementFormattersMap: [StandardElementType: AttributeFormatter] = {
        return [
            .blockquote: self.blockquoteFormatter,
            .div: self.divFormatter,
            .ol: self.orderedListFormatter,
            .ul: self.unorderedListFormatter,
            .strong: self.boldFormatter,
            .em: self.italicFormatter,
            .u: self.underlineFormatter,
            .del: self.strikethroughFormatter,
            .a: self.linkFormatter,
            .h1: self.h1Formatter,
            .h2: self.h2Formatter,
            .h3: self.h3Formatter,
            .h4: self.h4Formatter,
            .h5: self.h5Formatter,
            .h6: self.h6Formatter,
            .p: self.paragraphFormatter,
            .pre: self.preFormatter,
        ]
    }()

    let attributesToFormattersMap: [StandardHTMLAttribute: AttributeFormatter] = [:]

    public let styleToFormattersMap: [String: (AttributeFormatter, (String)->Any?)] = [
        "color": (ColorFormatter(), {(value) in return UIColor(hexString: value)}),
        "text-decoration": (UnderlineFormatter(), { (value) in return value == "underline" ? NSUnderlineStyle.styleSingle.rawValue : nil})
    ]

    // MARK: - Element Converters

    public lazy var elementConverters: [ElementConverter] = {
        return [
            self.brElementConverter,
            self.figureElementConverter,
            self.imageElementConverter,
            self.videoElementConverter,
            self.hrElementConverter,
        ]
    }()

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

    // MARK: - NSAttributedString attribute generation

    /// Calculates the attributes for the specified node.  Returns a dictionary including inherited
    /// attributes.
    ///
    /// - Parameters:
    ///     - element: the node to get the information from.
    ///     - inheritedAttributes: the inherited attributes from parent nodes.
    ///
    /// - Returns: an attributes dictionary, for use in an NSAttributedString.
    ///
    func attributes(for element: ElementNode, inheriting inheritedAttributes: [AttributedStringKey: Any]) -> [AttributedStringKey: Any] {

        guard !(element is RootNode) else {
            return inheritedAttributes
        }

        let elementRepresentation = HTMLElementRepresentation(element)
        let representation = HTMLRepresentation(for: .element(elementRepresentation))
        var finalAttributes = inheritedAttributes

        if let elementFormatter = formatter(for: element) {
            finalAttributes = elementFormatter.apply(to: finalAttributes, andStore: representation)
        } else if element.standardName == .li || converter(for: element) != nil {
            finalAttributes = inheritedAttributes
        } else {
            finalAttributes = self.attributes(storing: elementRepresentation, in: finalAttributes)
        }

        finalAttributes = self.attributes(for: element.attributes, inheriting: finalAttributes)
        
        return finalAttributes
    }

    /// Calculates the attributes for the specified HTML attributes.  Returns a dictionary
    /// including the inherited attributes.
    ///
    /// - Parameters:
    ///     - htmlAttributes: the HTML attributes to calculate the string attributes from.
    ///     - inheritedAttributes: the attributes that will be inherited.
    ///
    /// - Returns: an attributes dictionary, for use in an NSAttributedString.
    ///
    private func attributes(for htmlAttributes: [Attribute], inheriting inheritedAttributes: [AttributedStringKey: Any]) -> [AttributedStringKey: Any] {

        let finalAttributes = htmlAttributes.reduce(inheritedAttributes) { (previousAttributes, htmlAttribute) -> [AttributedStringKey: Any] in
            return attributes(for: htmlAttribute, inheriting: previousAttributes)
        }

        return finalAttributes
    }


    /// Calculates the attributes for the specified HTML attribute.  Returns a dictionary
    /// including inherited attributes.
    ///
    /// - Parameters:
    ///     - attribute: the attribute to calculate the string attributes from.
    ///     - inheritedAttributes: the attributes that will be inherited.
    ///
    /// - Returns: an attributes dictionary, for use in an NSAttributedString.
    ///
    private func attributes(for attribute: Attribute, inheriting inheritedAttributes: [AttributedStringKey: Any]) -> [AttributedStringKey: Any] {

        let attributes: [AttributedStringKey: Any]

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
    ///     - representation: Instance of HTMLElementRepresentation to be stored.
    ///     - attributes: Attributes where we should store the HTML Representation.
    ///
    /// - Returns: A collection of NSAttributedString Attributes, including the specified HTMLElementRepresentation.
    ///
    private func attributes(storing representation: HTMLElementRepresentation, in attributes: [AttributedStringKey: Any]) -> [AttributedStringKey: Any] {
        let unsupportedHTML = attributes[.unsupportedHtml] as? UnsupportedHTML
        var representations = unsupportedHTML?.representations ?? []
        representations.append(representation)

        // Note:
        // We'll *ALWAYS* store a copy of the UnsupportedHTML instance. Reason is: reusing the old instance
        // would mean affecting a range that may fall beyond what we expected!
        //
        var updated = attributes
        updated[.unsupportedHtml] = UnsupportedHTML(representations: representations)

        return updated
    }
}

extension AttributedStringSerializer {

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

        for (key, formatter) in elementFormattersMap {
            if equivalentNames.contains(key.rawValue) {
                return formatter
            }
        }

        return nil
    }

}

private extension AttributedStringSerializer {

    // MARK: - Element Converters

    /// Some element types have an implicit representation that doesn't really follow the standard
    /// conversion logic.  Element Converters take care of that.
    ///
    func converter(for element: ElementNode) -> ElementConverter? {
        return elementConverters.first { converter in
            converter.canConvert(element: element)
        }
    }
}


// MARK: - Text Sanitization for Rendering

private extension AttributedStringSerializer {
    
    func sanitizeText(from textNode: TextNode) -> String {
        guard shouldSanitizeText(for: textNode) else {
            return textNode.text()
        }
        
        return sanitize(textNode.text())
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
