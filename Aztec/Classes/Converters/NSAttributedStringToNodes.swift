import Foundation
import UIKit
import libxml2


// MARK: - NSAttributedStringToNodes
//
class NSAttributedStringToNodes: Converter {

    /// Typealiases
    ///
    typealias Node = Libxml2.Node
    typealias CommentNode = Libxml2.CommentNode
    typealias ElementNode = Libxml2.ElementNode
    typealias RootNode = Libxml2.RootNode
    typealias TextNode = Libxml2.TextNode
    typealias DOMString = Libxml2.DOMString
    typealias Attribute = Libxml2.Attribute
    typealias StringAttribute = Libxml2.StringAttribute
    typealias StandardElementType = Libxml2.StandardElementType


    ///
    ///
    func convert(_ attrString: NSAttributedString) -> RootNode {
        var previousParagraphStyles = [ElementNode]()
        var nodes = [Node]()

        attrString.enumerateParagraphRanges(spanning: attrString.rangeOfEntireString) { (paragraphRange, _) in
            let paragraph = attrString.attributedSubstring(from: paragraphRange)
            let (children, paragraphStyles) = createNodes(fromParagraph: paragraph)

            if !merge(left: previousParagraphStyles, right: paragraphStyles) {
                nodes += children
            }

            previousParagraphStyles = paragraphStyles
        }

        return RootNode(children: nodes)
    }


    ///
    ///
    private func createNodes(fromParagraph paragraph: NSAttributedString) -> ([Node], [ElementNode]) {
        var children = [Node]()

        guard paragraph.length > 0 else {
            return ([], [])
        }

        paragraph.enumerateAttributes(in: paragraph.rangeOfEntireString, options: []) { (attrs, range, _) in

            let substring = paragraph.attributedSubstring(from: range)
            let leaves = createLeafNodes(from: substring)
            let nodes = createStyleNodes(from: attrs, leaves: leaves)

            children.append(contentsOf: nodes)
        }

        let (paragraphElement, paragraphNodes) = createParagraphElement(from: paragraph, children: children)

        guard let theParagraphElement = paragraphElement else {
            return (children, [])
        }

        return ([theParagraphElement], paragraphNodes)
    }
}


// MARK: - Restoring Dimensionality
//
private extension NSAttributedStringToNodes {

    ///
    ///
    func merge(left: [ElementNode], right: [ElementNode]) -> Bool {
        guard let (target, source) = findLowestMergeableNodes(left: left, right: right) else {
            return false
        }

        target.children += source.children

        return true
    }


    ///
    ///
    private func findLowestMergeableNodes(left: [ElementNode], right: [ElementNode]) -> (ElementNode, ElementNode)? {
        var currentIndex = 0
        var match: (ElementNode, ElementNode)?

        while currentIndex < left.count && currentIndex < right.count {
            let left = left[currentIndex]
            let right = right[currentIndex]

            guard left.canMergeChildren(of: right) else {
                break
            }

            match = (left, right)
            currentIndex += 1
        }
        
        return match
    }
}


// MARK: - Node Creation
//
private extension NSAttributedStringToNodes {

    /// Creates an ElementNode from an AttributedString
    ///
    /// - Parameters:
    ///     - attrString: AttributedString from which we intend to extract the ElementNode
    ///     - children: Array of Node instances to be set as children
    ///
    /// - Returns: the root ElementNode
    ///
    func createParagraphElement(from attrString: NSAttributedString, children: [Node]) -> (ElementNode?, [ElementNode]) {
        guard let paragraphStyle = attrString.attribute(NSParagraphStyleAttributeName, at: 0, effectiveRange: nil) as? ParagraphStyle else {
            return (nil, [])
        }

        var lastNodes: [ElementNode]?
        var elements = [ElementNode]()

        enumerateParagraphNodes(in: paragraphStyle) { node in
            node.children = lastNodes ?? children
            lastNodes = [node]

            elements.insert(node, at: 0)
        }

        return (lastNodes?.first, elements)
    }


    ///
    ///
    func createStyleNodes(from attrs: [String: Any], leaves: [Node]) -> [Node] {
        var lastNodes: [ElementNode]?

        enumerateStyleNodes(in: attrs) { node in
            node.children = lastNodes ?? leaves
            lastNodes = [node]
        }

        return lastNodes ?? leaves
    }


    ///
    ///
    func createLeafNodes(from attrString: NSAttributedString) -> [Node] {
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
}


// MARK: - Style Extraction
//
private extension NSAttributedStringToNodes {

    ///
    ///
    func enumerateParagraphNodes(in style: ParagraphStyle, block: ((ElementNode) -> Void)) {
        if style.blockquote != nil {
            block( ElementNode(type: .blockquote) )
        }

        if style.htmlParagraph != nil {
            block( ElementNode(type: .p) )
        }

        if style.headerLevel > 0 {
            let header = DOMString.elementTypeForHeaderLevel(style.headerLevel) ?? .h1
            block( ElementNode(type: header) )
        }

        if !style.textLists.isEmpty {
            block( ElementNode(type: .li) )
        }

        for list in style.textLists {
            if list.style == .ordered {
                block( ElementNode(type: .ol) )
            } else {
                block( ElementNode(type: .ul) )
            }
        }
    }


    ///
    ///
    func enumerateStyleNodes(in attributes: [String: Any], block: ((ElementNode) -> Void)) {
        for (key, value) in attributes {
            switch key {
            case NSFontAttributeName:
                guard let font = value as? UIFont else {
                    break
                }

                if font.containsTraits(.traitBold) == true {
                    block( ElementNode(type: .b) )
                }

                if font.containsTraits(.traitItalic) == true {
                    block( ElementNode(type: .i) )
                }

            case NSLinkAttributeName:
                guard let url = value as? URL else {
                    break
                }

                let source = StringAttribute(name: "href", value: url.absoluteString)
                block( ElementNode(type: .a, attributes: [source]) )

            case NSStrikethroughStyleAttributeName:
                block( ElementNode(type: .strike) )

            case NSUnderlineStyleAttributeName:
                block( ElementNode(type: .u) )

            default:
                break
            }
        }
    }
}


// MARK: - Leaf Nodes
//
private extension NSAttributedStringToNodes {

    ///
    ///
    func lineAttachmentToNode(_ lineAttachment: LineAttachment) -> ElementNode {
        return ElementNode(type: .hr)
    }


    ///
    ///
    func commentAttachmentToNode(_ attachment: CommentAttachment) -> CommentNode {
        return CommentNode(text: attachment.text)
    }


    ///
    ///
    func htmlAttachmentToNode(_ attachment: HTMLAttachment) -> [Node] {
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
    func imageAttachmentToNode(_ attachment: ImageAttachment) -> ElementNode {
        var attributes = [Attribute]()
        if let url = attachment.url {
            let source = StringAttribute(name: "src", value: url.absoluteString)
            attributes.append(source)
        }

        return ElementNode(type: .img, attributes: attributes)
    }


    ///
    ///
    func textToNode(_ text: String) -> [Node] {
        let substrings = text.components(separatedBy: String(.newline))
        var output = [Node]()

        for substring in substrings {
            if output.count > 0 {
                let newline = ElementNode(type: .br)
                output.append(newline)
            }

            let text = TextNode(text: substring)
            output.append(text)
        }
        
        return output
    }
}
