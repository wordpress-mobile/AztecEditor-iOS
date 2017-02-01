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

    // MARK: - Visual-only Elements

    let visualOnlyElementFactory = VisualOnlyElementFactory()

    // MARK: - Initializers

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
    func convert(_ node: Node) -> NSAttributedString {

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
    fileprivate func convert(_ node: Node, inheritingAttributes attributes: [String:Any]) -> NSAttributedString {

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
    fileprivate func convertTextNode(_ node: TextNode, inheritingAttributes inheritedAttributes: [String:Any]) -> NSAttributedString {
        guard node.length() > 0 else {
            return NSAttributedString()
        }

        let content = NSMutableAttributedString(string: node.text(), attributes: inheritedAttributes)

        if node.isLastInBlockLevelElement() {
            content.append(visualOnlyElementFactory.newline(inheritingAttributes: inheritedAttributes))
        }

        return content
    }

    /// Converts a `CommentNode` to `NSAttributedString`.
    ///
    /// - Parameters:
    ///     - node: the node to convert to `NSAttributedString`.
    ///     - attributes: the inherited attributes from parent nodes.
    ///
    /// - Returns: the converted node as an `NSAttributedString`.
    ///
    fileprivate func convertCommentNode(_ node: CommentNode, inheritingAttributes inheritedAttributes: [String:Any]) -> NSAttributedString {
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
    fileprivate func convertElementNode(_ node: ElementNode, inheritingAttributes attributes: [String:Any]) -> NSAttributedString {
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
    fileprivate func stringForNode(_ node: ElementNode, inheritingAttributes inheritedAttributes: [String:Any]) -> NSAttributedString {
        
        let childAttributes = attributes(forNode: node, inheritingAttributes: inheritedAttributes)
        
        if let nodeType = node.standardName,
            let implicitRepresentation = nodeType.implicitRepresentation(withAttributes: childAttributes) {
            
            return implicitRepresentation
        }
        
        let content = NSMutableAttributedString()
        
        for child in node.children {
            let childContent = convert(child, inheritingAttributes: childAttributes)
            content.append(childContent)
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
    fileprivate func attributes(forNode node: ElementNode, inheritingAttributes inheritedAttributes: [String:Any]) -> [String:Any] {

        var attributes = inheritedAttributes

        // Since a default font is requested by this class, there's no way this attribute should
        // ever be unset.
        //
        precondition(inheritedAttributes[NSFontAttributeName] is UIFont)
        let baseFont = inheritedAttributes[NSFontAttributeName] as! UIFont
        let baseFontDescriptor = baseFont.fontDescriptor
        let descriptor = fontDescriptor(forNode: node, withBaseFontDescriptor: baseFontDescriptor)

        if descriptor != baseFontDescriptor {
            attributes[NSFontAttributeName] = UIFont(descriptor: descriptor, size: descriptor.pointSize)
        }

        if isLink(node) {
            let linkURL: String

            if let attributeIndex = node.attributes.index(where: { $0.name == HTMLLinkAttribute.Href.rawValue }),
                let attribute = node.attributes[attributeIndex] as? StringAttribute {

                linkURL = attribute.value
            } else {
                // We got a link tag without an HREF attribute
                //
                linkURL = ""
            }

            attributes[NSLinkAttributeName] = linkURL as AnyObject?
        }

        if isStrikedThrough(node) {
            attributes[NSStrikethroughStyleAttributeName] = NSUnderlineStyle.styleSingle.rawValue as AnyObject?
        }

        if isUnderlined(node) {
            attributes[NSUnderlineStyleAttributeName] = NSUnderlineStyle.styleSingle.rawValue as AnyObject?
        }

        if isBlockquote(node) {
            let formatter = BlockquoteFormatter()
            attributes = formatter.apply(to: attributes)
        }

        if isImage(node) {
            let url: URL?

            if let urlString = node.valueForStringAttribute(named: "src") {
                url = URL(string: urlString)
            } else {
                url = nil
            }

            let attachment = TextAttachment(identifier: UUID().uuidString, url: url)

            if let elementClass = node.valueForStringAttribute(named: "class") {
                let classAttributes = elementClass.components(separatedBy: " ")
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
            let formatter = TextListFormatter(style: .ordered)
            attributes = formatter.apply(to: attributes)
        }

        if node.isNodeType(.ul) {
            let formatter = TextListFormatter(style: .unordered)
            attributes = formatter.apply(to: attributes)
        }

        return attributes
    }

    // MARK: - Font

    fileprivate func fontDescriptor(forNode node: ElementNode, withBaseFontDescriptor fontDescriptor: UIFontDescriptor) -> UIFontDescriptor {
        let traits = symbolicTraits(forNode: node, withBaseSymbolicTraits: fontDescriptor.symbolicTraits)

        return fontDescriptor.withSymbolicTraits(traits)!
    }

    /// Gets a list of symbolic traits representing the specified node.
    ///
    /// - Parameters:
    ///     - node: the node to get the traits from.
    ///
    /// - Returns: the requested symbolic traits.
    ///
    fileprivate func symbolicTraits(forNode node: ElementNode, withBaseSymbolicTraits baseTraits: UIFontDescriptorSymbolicTraits) -> UIFontDescriptorSymbolicTraits {

        var traits = baseTraits

        if isBold(node) {
            traits.insert(.traitBold)
        }

        if isItalic(node) {
            traits.insert(.traitItalic)
        }

        return traits
    }

    // MARK: - Node Style Checks

    fileprivate func isLink(_ node: ElementNode) -> Bool {
        return node.name == StandardElementType.a.rawValue
    }

    fileprivate func isBold(_ node: ElementNode) -> Bool {
        return StandardElementType.b.equivalentNames.contains(node.name)
    }

    fileprivate func isItalic(_ node: ElementNode) -> Bool {
        return StandardElementType.i.equivalentNames.contains(node.name)
    }

    fileprivate func isStrikedThrough(_ node: ElementNode) -> Bool {
        return StandardElementType.s.equivalentNames.contains(node.name)
    }

    fileprivate func isUnderlined(_ node: ElementNode) -> Bool {
        return node.name == StandardElementType.u.rawValue
    }

    fileprivate func isBlockquote(_ node: ElementNode) -> Bool {
        return node.name == StandardElementType.blockquote.rawValue
    }

    fileprivate func isImage(_ node: ElementNode) -> Bool {
        return node.name == StandardElementType.img.rawValue
    }    
}
