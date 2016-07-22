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

    /// Main conversion method.
    ///
    func convert(node: Node) -> NSAttributedString {

        if let textNode = node as? TextNode {
            return NSAttributedString(string: textNode.text, attributes: [keyForNode(textNode): textNode])
        } else {
            guard let elementNode = node as? ElementNode else {
                fatalError("Nodes can be either text or element nodes.")
            }

            if elementNode.children.count == 0 {
                return stringForEmptyNode(elementNode)
            } else {
                return stringForNode(elementNode)
            }
        }
    }

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

    /// Returns an attributed string representing the specified non-empty node.  Non-empty means
    /// the received node has children.
    ///
    /// - Parameters:
    ///     - elementNode: the element node to generate a representation string of.
    ///
    /// - Returns: the attributed string representing the specified element node.
    ///
    ///
    private func stringForNode(elementNode: ElementNode) -> NSAttributedString {
        assert(elementNode.children.count > 0)

        let content = NSMutableAttributedString()

        for child in elementNode.children {
            let childContent = convert(child)

            content.appendAttributedString(childContent)
        }

        addAttributes(toString: content, fromNode: elementNode)

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

        let traits = symbolicTraits(fromNode: node)
        let newFontDescriptor = defaultFontDescriptor.fontDescriptorWithSymbolicTraits(traits)
        let newFont = UIFont(descriptor: newFontDescriptor, size: newFontDescriptor.pointSize)

        string.addAttribute(NSFontAttributeName, value: newFont, range: fullRange)
    }

    /// Gets a list of symbolic traits representing the specified node.
    ///
    /// - Parameters:
    ///     - node: the node to get the traits from.
    ///
    /// - Returns: the requested symbolic traits.
    ///
    private func symbolicTraits(fromNode node: ElementNode) -> UIFontDescriptorSymbolicTraits {
        var traits = UIFontDescriptorSymbolicTraits(rawValue: 0)

        let isBold = node.name == "b" || node.name == "strong"
        let isItalic = node.name == "em" || node.name == "i"

        if isBold {
            traits.insert(.TraitBold)
        }

        if isItalic {
            traits.insert(.TraitItalic)
        }

        return traits
    }
}