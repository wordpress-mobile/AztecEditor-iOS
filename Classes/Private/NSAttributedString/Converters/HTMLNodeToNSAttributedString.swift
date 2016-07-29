import Foundation

class HMTLNodeToNSAttributedString: SafeConverter {
    typealias HTML = Libxml2.HTML
    typealias ElementNode = HTML.ElementNode
    typealias Node = HTML.Node
    typealias TextNode = HTML.TextNode

    /// The default font descriptor that will be used as a base for conversions.
    ///
    let defaultFontDescriptor: UIFontDescriptor

    required init(usingDefaultFontDescriptor defaultFontDescriptor: UIFontDescriptor) {
        self.defaultFontDescriptor = defaultFontDescriptor
    }

    // MARK: - Conversion

    /// Main conversion method.
    ///
    /// - Parameters:
    ///     - node: the node to convert to `NSAttributedString`.
    ///
    /// - Returns: the converted node as an `NSAttributedString`.
    ///
    func convert(node: Node) -> NSAttributedString {

        let defaultFont = UIFont(descriptor: defaultFontDescriptor, size: defaultFontDescriptor.pointSize)

        return convert(node, inheritingAttributes: [NSFontAttributeName: defaultFont])
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
    private func convert(node: Node, inheritingAttributes attributes: [String:AnyObject]) -> NSAttributedString {

        if let textNode = node as? TextNode {
            return convertTextNode(textNode, inheritingAttributes: attributes)
        } else {
            guard let elementNode = node as? ElementNode else {
                fatalError("Nodes can be either text or element nodes.")
            }

            return convertElementNode(elementNode, inheritingAttributes: attributes)
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
    private func convertTextNode(node: TextNode, inheritingAttributes inheritedAttributes: [String:AnyObject]) -> NSAttributedString {

        var attributes = inheritedAttributes
        attributes[keyForNode(node)] = node

        return NSAttributedString(string: node.text, attributes: attributes)
    }

    /// Converts an `ElementNode` to `NSAttributedString`.
    ///
    /// - Parameters:
    ///     - node: the node to convert to `NSAttributedString`.
    ///     - attributes: the inherited attributes from parent nodes.
    ///
    /// - Returns: the converted node as an `NSAttributedString`.
    ///
    private func convertElementNode(node: ElementNode, inheritingAttributes attributes: [String:AnyObject]) -> NSAttributedString {

        if node.children.count == 0 {
            return stringForEmptyNode(node)
        } else {
            return stringForNode(node, inheritingAttributes: attributes)
        }
    }

    // MARK: - Unique Key Generation

    /// Generates a unique ID for the specified node.
    ///
    private func keyForNode(node: Node) -> String {

        if node.name == Aztec.AttributeName.rootNode {
            return node.name
        } else {
            let uuid = NSUUID().UUIDString

            return "Aztec.HTMLTag.\(node.name).\(uuid)"
        }
    }

    // MARK: - Node Styling

    /// Returns an attributed string representing the specified non-empty node.  Non-empty means
    /// the received node has children.
    ///
    /// - Parameters:
    ///     - node: the element node to generate a representation string of.
    ///     - inheritedAttributes: the inherited attributes from parent nodes.
    ///
    /// - Returns: the attributed string representing the specified element node.
    ///
    ///
    private func stringForNode(node: ElementNode, inheritingAttributes inheritedAttributes: [String:AnyObject]) -> NSAttributedString {
        assert(node.children.count > 0)

        let content = NSMutableAttributedString()
        let childAttributes = attributes(forNode: node, inheritingAttributes: inheritedAttributes)

        for child in node.children {
            let childContent = convert(child, inheritingAttributes: childAttributes)

            content.appendAttributedString(childContent)
        }

        content.addAttribute(keyForNode(node), value: node, range: NSRange(location: 0, length: content.length))

        return content
    }

    /// Returns an attributed string representing the specified empty node.  Empty means the
    /// received node has no children.
    ///
    /// - Parameters:
    ///     - elementNode: the element node to generate a representation string of.
    ///
    /// - Returns: the attributed string representing the specified element node.
    ///
    private func stringForEmptyNode(elementNode: ElementNode) -> NSAttributedString {
        assert(elementNode.children.count == 0)

        let placeholderContent: String

        if elementNode.name.lowercaseString == "br" {
            placeholderContent = "\n";
        } else {
            let objectReplacementCharacter = "\u{fffc}"

            placeholderContent = objectReplacementCharacter
        }

        return NSAttributedString(string: placeholderContent, attributes: [keyForNode(elementNode): elementNode])
    }

    // MARK: - String attributes

    /// Calculates the attributes for the specified node.  Returns a dictionary including inherited
    /// attributes.
    ///
    /// - Parameters:
    ///     - node: the node to get the information from.
    ///
    /// - Returns: an attributes dictionary, for use in an NSAttributedString.
    ///
    private func attributes(forNode node: ElementNode, inheritingAttributes inheritedAttributes: [String:AnyObject]) -> [String:AnyObject] {

        var attributes = inheritedAttributes

        // Since a default font is requested by this class, there's no way this attribute should
        // ever be unset.
        //
        precondition(inheritedAttributes[NSFontAttributeName] is UIFont)
        let baseFont = inheritedAttributes[NSFontAttributeName] as! UIFont
        let baseFontDescriptor = baseFont.fontDescriptor()
        let descriptor = fontDescriptor(forNode: node, withBaseFontDescriptor: baseFontDescriptor)

        if descriptor != baseFontDescriptor {
            attributes[NSFontAttributeName] = UIFont(descriptor: descriptor, size: descriptor.pointSize)
        }

        if isLink(node) {
            let linkURL: String

            if let attribute = node.attributes.indexOf({ $0.name == HTMLLinkAttributes.Href.rawValue }) as? Libxml2.HTML.StringAttribute {
                linkURL = attribute.value
            } else {
                // We got a link tag without an HREF attribute
                //
                linkURL = ""
            }

            attributes[NSLinkAttributeName] = linkURL
        }

        if isStrikedThrough(node) {
            attributes[NSStrikethroughStyleAttributeName] = NSUnderlineStyle.StyleSingle.rawValue
        }

        if isUnderlined(node) {
            attributes[NSUnderlineStyleAttributeName] = NSUnderlineStyle.StyleSingle.rawValue
        }

        return attributes
    }

    // MARK: - Font

    private func fontDescriptor(forNode node: ElementNode, withBaseFontDescriptor fontDescriptor: UIFontDescriptor) -> UIFontDescriptor {
        let traits = symbolicTraits(forNode: node, withBaseSymbolicTraits: fontDescriptor.symbolicTraits)

        return fontDescriptor.fontDescriptorWithSymbolicTraits(traits)
    }

    /// Gets a list of symbolic traits representing the specified node.
    ///
    /// - Parameters:
    ///     - node: the node to get the traits from.
    ///
    /// - Returns: the requested symbolic traits.
    ///
    private func symbolicTraits(forNode node: ElementNode, withBaseSymbolicTraits baseTraits: UIFontDescriptorSymbolicTraits) -> UIFontDescriptorSymbolicTraits {

        var traits = baseTraits

        if isBold(node) {
            traits.insert(.TraitBold)
        }

        if isItalic(node) {
            traits.insert(.TraitItalic)
        }

        return traits
    }

    // MARK: - Node Style Checks

    private func isLink(node: ElementNode) -> Bool {
        return node.name == HTMLTags.A.rawValue
    }

    private func isBold(node: ElementNode) -> Bool {
        return [HTMLTags.B.rawValue,
            HTMLTags.Strong.rawValue].contains(node.name)
    }

    private func isItalic(node: ElementNode) -> Bool {
        return [HTMLTags.Em.rawValue,
            HTMLTags.I.rawValue].contains(node.name)
    }

    private func isStrikedThrough(node: ElementNode) -> Bool {
        return [HTMLTags.Del.rawValue,
            HTMLTags.S.rawValue,
            HTMLTags.Strike.rawValue].contains(node.name)
    }

    private func isUnderlined(node: ElementNode) -> Bool {
        return node.name == HTMLTags.U.rawValue
    }
}