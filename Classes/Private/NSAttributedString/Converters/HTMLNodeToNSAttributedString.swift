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
        return convert(node, withBaseFontDescriptor: defaultFontDescriptor)
    }

    /// Recursive conversion method.  Useful for maintaining the font style of parent nodes when
    /// converting.
    ///
    /// - Parameters:
    ///     - node: the node to convert to `NSAttributedString`.
    ///     - baseFontDescriptor: the base font descriptor to use for this node's conversion.  Any
    ///             change to the font style will be applied on top of this base descriptor.
    ///
    /// - Returns: the converted node as an `NSAttributedString`.
    ///
    private func convert(node: Node, withBaseFontDescriptor baseFontDescriptor: UIFontDescriptor) -> NSAttributedString {

        if let textNode = node as? TextNode {
            return convertTextNode(textNode, withBaseFontDescriptor: baseFontDescriptor)
        } else {
            guard let elementNode = node as? ElementNode else {
                fatalError("Nodes can be either text or element nodes.")
            }

            return convertElementNode(elementNode, withBaseFontDescriptor: baseFontDescriptor)
        }
    }

    /// Converts a `TextNode` to `NSAttributedString`.
    ///
    /// - Parameters:
    ///     - node: the node to convert to `NSAttributedString`.
    ///     - baseFontDescriptor: the base font descriptor to use for this node's conversion.
    ///             Text nodes don't have styling information, so this will be used as-is.
    ///
    /// - Returns: the converted node as an `NSAttributedString`.
    ///
    private func convertTextNode(node: TextNode, withBaseFontDescriptor baseFontDescriptor: UIFontDescriptor) -> NSAttributedString {

        let font = UIFont(descriptor: baseFontDescriptor, size: baseFontDescriptor.pointSize)
        let attributes: [String:AnyObject] = [keyForNode(node): node,
                                              NSFontAttributeName: font]

        return NSAttributedString(string: node.text, attributes: attributes)
    }

    /// Converts an `ElementNode` to `NSAttributedString`.
    ///
    /// - Parameters:
    ///     - node: the node to convert to `NSAttributedString`.
    ///     - baseFontDescriptor: the base font descriptor to use for this node's conversion.
    ///             Text nodes don't have styling information, so this will be used as-is.
    ///
    /// - Returns: the converted node as an `NSAttributedString`.
    ///
    private func convertElementNode(node: ElementNode, withBaseFontDescriptor baseFontDescriptor: UIFontDescriptor) -> NSAttributedString {

        if node.children.count == 0 {
            return stringForEmptyNode(node)
        } else {
            return stringForNode(node, withBaseFontDescriptor: baseFontDescriptor)
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
    ///     - elementNode: the element node to generate a representation string of.
    ///
    /// - Returns: the attributed string representing the specified element node.
    ///
    ///
    private func stringForNode(node: ElementNode, withBaseFontDescriptor baseFontDescriptor: UIFontDescriptor) -> NSAttributedString {
        assert(node.children.count > 0)

        let content = NSMutableAttributedString(string: "XX")
        let descriptor = fontDescriptor(forNode: node, withBaseFontDescriptor: baseFontDescriptor)

        content.addAttribute(NSFontAttributeName, value: font(forNode: node, withBaseFontDescriptor: baseFontDescriptor), range: NSRange(location: 0, length: content.length))

        let childrenContent = NSMutableAttributedString()

        for child in node.children {
            let childContent = convert(child, withBaseFontDescriptor: descriptor)

            childrenContent.appendAttributedString(childContent)
        }

        content.replaceCharactersInRange(NSRange(location: 0, length: content.length), withAttributedString: childrenContent)
        content.addAttribute(keyForNode(node), value: node, range: NSRange(location: 0, length: content.length))
        addAttributes(toString: content, fromNode: node)

        //content.insertAttributedString(childrenContent, atIndex: 1)

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

    /// Adds all HTML-meta data and style attributes from the specified element node to the
    /// specified string.
    ///
    /// - Parameters:
    ///     - string: the string to add the attributes to.  This string will be modified in-place
    ///             to add the necessary attributes.
    ///     - node: the node to get the information from.
    ///
    private func addAttributes(toString string: NSMutableAttributedString, fromNode node: ElementNode) {

        let fullRange = NSRange(location: 0, length: string.length)

        addStyleAttributes(toString: string, fromNode: node)
        string.addAttribute(keyForNode(node), value: node, range: fullRange)
    }

    /// Adds all style attributes from the specified element node to the specified string.
    /// You'll usually want to call `addAttributes(toString:fromNode:)` instead of this method.
    ///
    /// - Parameters:
    ///     - string: the string to apply the styles to.  This string will be modified in-place
    ///             to add the necessary attributes.
    ///     - node: the node to get the style information from.
    ///
    private func addStyleAttributes(toString string: NSMutableAttributedString, fromNode node: ElementNode) {

        let fullRange = NSRange(location: 0, length: string.length)

        if isUnderlined(node) {
            string.addAttribute(NSUnderlineStyleAttributeName, value: 1, range: fullRange)
        }

        if isStrikedThrough(node) {
            string.addAttribute(NSStrikethroughStyleAttributeName, value: 1, range: fullRange)
        }

        if isBlockquote(node) {
            let style = NSMutableParagraphStyle()
            style.headIndent = Metrics.defaultIndentation
            style.firstLineHeadIndent = style.headIndent
            string.addAttribute(NSParagraphStyleAttributeName, value: style, range: fullRange)
        }

        //string.addAttribute(NSFontAttributeName, value: font(forNode: node), range: fullRange)
    }

    // MARK: - Font

    /// Returns the correct font for the specified node.  Includes "bold" and "italic" styling
    /// information.
    ///
    /// - Parameters:
    ///     - node: the node to get the font for.
    ///
    /// - Returns: the requested font.
    ///
    private func font(forNode node: ElementNode, withBaseFontDescriptor baseFontDescriptor: UIFontDescriptor) -> UIFont {

        let newFontDescriptor = fontDescriptor(forNode: node, withBaseFontDescriptor: baseFontDescriptor)

        return UIFont(descriptor: newFontDescriptor, size: newFontDescriptor.pointSize)
    }

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

    // MARK: - Node styling

    private func isBold(node: ElementNode) -> Bool {
        return ["b", "strong"].contains(node.name)
    }

    private func isItalic(node: ElementNode) -> Bool {
        return ["em", "i"].contains(node.name)
    }

    private func isStrikedThrough(node: ElementNode) -> Bool {
        return ["strike", "del", "s"].contains(node.name)
    }

    private func isUnderlined(node: ElementNode) -> Bool {
        return ["u"].contains(node.name)
    }

    private func isBlockquote(node: ElementNode) -> Bool {
        return ["blockquote"].contains(node.name)
    }
}