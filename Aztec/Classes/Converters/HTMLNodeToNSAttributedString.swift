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
        return convert(node, inheritingAttributes: defaultAttributes)
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
        if node.comment == "more" {
            var attributes = inheritedAttributes;
            let moreAttachment = MoreAttachment()
            moreAttachment.message = NSAttributedString(string: NSLocalizedString("MORE", comment: "Text for the center of the   more divider"), attributes: defaultAttributes)
            attributes[NSAttachmentAttributeName] = moreAttachment
            return NSAttributedString(string:String(UnicodeScalar(NSAttachmentCharacter)!), attributes: attributes)
        }
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

        var attributeValue: Any?

        if node.isNodeType(.a) {
            let linkURL: String

            if let attributeIndex = node.attributes.index(where: { $0.name == HTMLLinkAttribute.Href.rawValue }),
                let attribute = node.attributes[attributeIndex] as? StringAttribute {

                linkURL = attribute.value
            } else {
                // We got a link tag without an HREF attribute
                //
                linkURL = ""
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
            attributeValue = attachment
        }

        for (key, formatter) in elementToFormattersMap {
            if node.isNodeType(key) {
                if let standardValueFormatter = formatter as? StandardAttributeFormatter,
                    let value = attributeValue {
                    standardValueFormatter.attributeValue = value
                }
                attributes = formatter.apply(to: attributes);
            }
        }

        return attributes
    }

    public let elementToFormattersMap: [StandardElementType: AttributeFormatter] = [
        .ol: TextListFormatter(style: .ordered),
        .ul: TextListFormatter(style: .unordered),
        .blockquote: BlockquoteFormatter(),
        .strong: BoldFormatter(),
        .em: ItalicFormatter(),
        .u: UnderlineFormatter(),
        .del: StrikethroughFormatter(),
        .a: LinkFormatter(),
        .img: ImageFormatter()
    ]
}
