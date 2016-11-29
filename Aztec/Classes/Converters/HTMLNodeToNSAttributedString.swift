import Foundation
import Gridicons
import UIKit

class HMTLNodeToNSAttributedString: SafeConverter {

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
        } else if let commentNode = node as? CommentNode {
            return convertCommentNode(commentNode, inheritingAttributes: attributes)
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
        return NSAttributedString(string: node.text(), attributes: inheritedAttributes)
    }

    /// Converts a `CommentNode` to `NSAttributedString`.
    ///
    /// - Parameters:
    ///     - node: the node to convert to `NSAttributedString`.
    ///     - attributes: the inherited attributes from parent nodes.
    ///
    /// - Returns: the converted node as an `NSAttributedString`.
    ///
    private func convertCommentNode(node: CommentNode, inheritingAttributes inheritedAttributes: [String:AnyObject]) -> NSAttributedString {
        return NSAttributedString(string: node.text(), attributes: inheritedAttributes)
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
        return stringForNode(node, inheritingAttributes: attributes)
    }

    // MARK: - Node Styling

    /// Returns an attributed string representing the specified node.
    ///
    /// - Parameters:
    ///     - node: the element node to generate a representation string of.
    ///     - inheritedAttributes: the inherited attributes from parent nodes.
    ///
    /// - Returns: the attributed string representing the specified element node.
    ///
    ///
    private func stringForNode(node: ElementNode, inheritingAttributes inheritedAttributes: [String:AnyObject]) -> NSAttributedString {

        let content = NSMutableAttributedString()
        let childAttributes = attributes(forNode: node, inheritingAttributes: inheritedAttributes)

        for child in node.children {
            let childContent = NSAttributedString(attributedString:convert(child, inheritingAttributes: childAttributes))
            content.appendAttributedString(childContent)
        }

        if node.isBlockLevelElement() && !node.isLastChildBlockLevelElement() {
            content.appendAttributedString(NSAttributedString(string: "\n", attributes: inheritedAttributes))
        }

        if let nodeType = node.standardName {
            return nodeType.implicitRepresentation(forContent: content, attributes: childAttributes)
        }

        return content
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

            if let attributeIndex = node.attributes.indexOf({ $0.name == HTMLLinkAttribute.Href.rawValue }),
                let attribute = node.attributes[attributeIndex] as? StringAttribute {

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

        if isBlockquote(node) {
            let formatter = BlockquoteFormatter()
            for (key, value) in formatter.attributes {
                attributes[key] = value
            }
        }

        if isImage(node) {
            let url: NSURL?

            if let urlString = node.valueForStringAttribute(named: "src") {
                url = NSURL(string: urlString)
            } else {
                url = nil
            }

            let attachment = TextAttachment(url: url)

            if let elementClass = node.valueForStringAttribute(named: "class") {
                let classAttributes = elementClass.componentsSeparatedByString(" ")
                for classAttribute in classAttributes {
                    if let alignment = TextAttachment.Alignment.fromHTML(string: classAttribute) {
                        attachment.alignment = alignment
                    }
                    if let size = TextAttachment.Size.fromHTML(string: classAttribute) {
                        attachment.size = size
                    }
                }
            }
            attributes[NSAttachmentAttributeName] = attachment
        }

        if node.isNodeType(.ol) {
            attributes[TextList.attributeName] = TextList(style: .Ordered)
        }

        if node.isNodeType(.ul) {
            attributes[TextList.attributeName] = TextList(style: .Unordered)
        }

        if node.isNodeType(.li) {
            if let listStyle = attributes[TextList.attributeName] as? TextList {
                listStyle.currentListNumber += 1
                attributes[TextListItem.attributeName] = TextListItem(number: listStyle.currentListNumber)
                attributes[NSParagraphStyleAttributeName] = NSParagraphStyle.Aztec.defaultListParagraphStyle
            }
        }

        return attributes
    }

    // MARK: - Font

    private func fontDescriptor(forNode node: ElementNode, withBaseFontDescriptor fontDescriptor: UIFontDescriptor) -> UIFontDescriptor {
        let traits = symbolicTraits(forNode: node, withBaseSymbolicTraits: fontDescriptor.symbolicTraits)

        return fontDescriptor.fontDescriptorWithSymbolicTraits(traits)!
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
        return node.name == StandardElementType.a.rawValue
    }

    private func isBold(node: ElementNode) -> Bool {
        return StandardElementType.b.equivalentNames.contains(node.name)
    }

    private func isItalic(node: ElementNode) -> Bool {
        return StandardElementType.i.equivalentNames.contains(node.name)
    }

    private func isStrikedThrough(node: ElementNode) -> Bool {
        return StandardElementType.s.equivalentNames.contains(node.name)
    }

    private func isUnderlined(node: ElementNode) -> Bool {
        return node.name == StandardElementType.u.rawValue
    }

    private func isBlockquote(node: ElementNode) -> Bool {
        return node.name == StandardElementType.blockquote.rawValue
    }

    private func isImage(node: ElementNode) -> Bool {
        return node.name == StandardElementType.img.rawValue
    }    
}
