import Foundation
import UIKit
import libxml2



// MARK: - NSAttributedStringToNodes
//
class NSAttributedStringToNodes {

    /// Typealiases
    ///
    typealias Node = Libxml2.Node
    typealias CommentNode = Libxml2.CommentNode
    typealias ElementNode = Libxml2.ElementNode
    typealias TextNode = Libxml2.TextNode
    typealias DOMString = Libxml2.DOMString
    typealias DOMInspector = Libxml2.DOMInspector
    typealias Attribute = Libxml2.Attribute
    typealias StringAttribute = Libxml2.StringAttribute

    func createNodes(fromText text: NSAttributedString) -> [Node] {
        var result = [Node]()
        let ranges = text.paragraphRanges()
        for range in ranges {
            let paragraph = text.attributedSubstring(from: range)
            result.append(contentsOf:createNodes(fromParagraph: paragraph))
        }
        return result
    }
    ///
    ///
    func createNodes(fromParagraph paragraph: NSAttributedString) -> [Node] {

        var children = [Node]()

        guard paragraph.length > 0 else {
            return []
        }

        paragraph.enumerateAttributes(in: paragraph.rangeOfEntireString, options: []) { (attrs, range, _) in

            let styles = domStyles(from: attrs)
            let leaves = leafNodes(from: paragraph.attributedSubstring(from: range))
            let nodes = createNodes(from: styles, leaves: leaves)

            children.append(contentsOf: nodes)
        }

        guard let paragraphElement = createParagraphElement(from: paragraph, withChildren: children) else {
            return children
        }

        return [paragraphElement]
    }
}


// MARK: - Leaf Nodes
//
private extension NSAttributedStringToNodes {

    ///
    ///
    func leafNodes(from attrString: NSAttributedString) -> [Node] {
        let attachment = attrString.attribute(NSAttachmentAttributeName, at: 0, effectiveRange: nil) as? NSTextAttachment
        var leafs = [Node]()

        switch attachment {
        case let lineAttachment as LineAttachment:
            let node = lineAttachmentToNode(lineAttachment)
            leafs.append(node)
        case let commentAttachment as CommentAttachment:
            let node = commentAttachmentToNode(commentAttachment)
            leafs.append(node)
        case let htmlAttachment as HTMLAttachment:
            let nodes = htmlAttachmentToNode(htmlAttachment)
            leafs.append(contentsOf: nodes)
        case let imageAttachment as ImageAttachment:
            let node = imageAttachmentToNode(imageAttachment)
            leafs.append(node)
        default:
            let nodes = textToNode(attrString.string)
            leafs.append(contentsOf: nodes)
        }

        return leafs
    }

    ///
    ///
    private func lineAttachmentToNode(_ lineAttachment: LineAttachment) -> ElementNode {
        return ElementNode(type: .hr, attributes: [], children: [])
    }


    ///
    ///
    private func commentAttachmentToNode(_ attachment: CommentAttachment) -> CommentNode {
        return CommentNode(text: attachment.text)
    }


    ///
    ///
    private func htmlAttachmentToNode(_ attachment: HTMLAttachment) -> [Node] {
        let converter = Libxml2.In.HTMLConverter()

        guard let rootNode = try? converter.convert(attachment.rawHTML),
            let firstChild = rootNode.children.first
        else {
            return textToNode(attachment.rawHTML)
        }

        guard rootNode.children.count == 1 else {
            let spanElement = ElementNode(type: .span, attributes: [], children: rootNode.children)
            return [spanElement]
        }

        return [firstChild]
    }


    ///
    ///
    private func imageAttachmentToNode(_ attachment: ImageAttachment) -> ElementNode {
        var attributes = [Attribute]()
        if let url = attachment.url {
            let source = StringAttribute(name: "src", value: url.absoluteString)
            attributes.append(source)
        }

        return ElementNode(type: .img, attributes: attributes, children: [])
    }


    ///
    ///
    private func textToNode(_ text: String) -> [Node] {
        let substrings = text.components(separatedBy: String(.newline))
        var output = [Node]()

        for substring in substrings {
            if output.count > 0 {
                let newline = ElementNode(type: Libxml2.StandardElementType.br)
                output.append(newline)
            }
            
            let text = TextNode(text: substring)
            output.append(text)
        }

        return output
    }
}



// MARK: - Node Creation
//
private extension NSAttributedStringToNodes {

    /// Creates an ElementNode from an AttributedString
    ///
    /// - Parameters:
    ///     - attrString: AttributedString from which we intend to extract the ElementNode
    ///     - childre: Array of Node instances to be set as children
    ///
    /// - Returns: the root ElementNode
    ///
    func createParagraphElement(from attrString: NSAttributedString, withChildren children: [Node]) -> ElementNode? {

        guard let paragraphStyle = attrString.attribute(NSParagraphStyleAttributeName, at: 0, effectiveRange: nil) as? ParagraphStyle else {
            return nil
        }

        let domParagraphStyles = self.domParagraphStyles(from: paragraphStyle)
        guard domParagraphStyles.isEmpty == false else {
            return nil
        }

        let element = domParagraphStyles.reversed().reduce(children) { (previous, style) -> [Node] in
            return [ style.toElement(children: previous) ]
        }

        guard let result = element.first as? ElementNode else {
            fatalError("The input array of paragraph styles cannot be empty, so this should not be possible.")
        }

        return result
    }


    ///
    ///
    func createNodes(from domStyles: [DOMStyle], leaves: [Node]) -> [Node] {
        let styleNodes = domStyles.reversed().reduce(leaves) { (children, style) in
            return [style.toNode(children: children)]
        }

        return styleNodes
    }
}


// MARK: - Style Extraction
//
private extension NSAttributedStringToNodes {

    /// Converts a ParagraphStyle into an array of DOMParagraphStyle Instances.
    ///
    func domParagraphStyles(from style: ParagraphStyle) -> [DOMParagraphStyle] {
        var styles = [DOMParagraphStyle]()

        if style.blockquote != nil {
            styles.append(.blockquote)
        }

        if style.htmlParagraph != nil {
            styles.append(.paragraph)
        }

        if style.headerLevel > 0 {
            styles.append(.header(level: style.headerLevel))
        }

        for paragraphHint in style.paragraphHints {
            if paragraphHint == .orderedList {
                styles.append(.orderedList)
            } else if paragraphHint == .unorderedList {
                styles.append(.unorderedList)
            }
        }

        return styles
    }


    /// Converts a collection of NSAttributedString (Key, Value)'s into an array of DOMStyle Instances.
    ///
    func domStyles(from attributes: [String: Any]) -> [DOMStyle] {
        var styles = [DOMStyle]()

        for (key, value) in attributes {
            styles.append(contentsOf: self.styles(key: key, value: value))
        }

        return styles
    }


    /// Converts an NSAttributedString Attribute : Value into an array of DOMStyle Instances.
    ///
    private func styles(key: String, value: Any) -> [DOMStyle] {
        var styles = [DOMStyle]()

        switch key {
        case NSFontAttributeName:
            guard let font = value as? UIFont else {
                break
            }

            if font.containsTraits(.traitBold) == true {
                styles.append(.bold)
            }

            if font.containsTraits(.traitItalic) == true {
                styles.append(.italics)
            }
        case NSLinkAttributeName:
            guard let url = value as? URL else {
                break
            }

            styles.append(.anchor(url: url.absoluteString))
        case NSStrikethroughStyleAttributeName:
            styles.append(.strike)
        case NSUnderlineStyleAttributeName:
            styles.append(.underlined)
        default:
            break
        }

        return styles
    }
}


// MARK: - Nested Types
//
private extension NSAttributedStringToNodes {

    // MARK: - DOMParagraphStyle
    //
    enum DOMParagraphStyle {
        case blockquote
        case header(level: Int)
        case horizontalRule
        case orderedList
        case paragraph
        case preformatted
        case unorderedList

        func toElement(children: [Node]) -> ElementNode {
            switch self {
            case .blockquote:
                return ElementNode(type: .blockquote, children: children)
            case .header(let level):
                let header = DOMString.elementTypeForHeaderLevel(level) ?? .p
                return ElementNode(type: header, children: children)
            case .horizontalRule:
                return ElementNode(type: .hr, children: children)
            case .orderedList:
                return ElementNode(type: .ol, children: children)
            case .paragraph:
                return ElementNode(type: .p, children: children)
            case .preformatted:
                return ElementNode(type: .pre, children: children)
            case .unorderedList:
                return ElementNode(type: .ul, children: children)
            }
        }
    }


    // MARK: - DOMStyle
    //
    enum DOMStyle {
        case anchor(url: String)
        case bold
        case italics
        case image(url: String)
        case strike
        case underlined

        func toNode(children: [Node]) -> ElementNode {
            switch self {
            case .anchor(let url):
                let source = StringAttribute(name: "href", value: url)
                return ElementNode(type: .a, attributes: [source], children: children)
            case .bold:
                return ElementNode(type: .b, children: children)
            case .italics:
                return ElementNode(type: .i, children: children)
            case .image(let url):
                let source = StringAttribute(name: "src", value: url)
                return ElementNode(type: .img, attributes: [source])
            case .strike:
                return ElementNode(type: .strike, children: children)
            case .underlined:
                return ElementNode(type: .u, children: children)
            }
        }
    }
}
