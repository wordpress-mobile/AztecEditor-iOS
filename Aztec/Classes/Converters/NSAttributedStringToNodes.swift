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
        var previous = [Node]()
        var nodes = [Node]()

        attrString.enumerateParagraphRanges(spanning: attrString.rangeOfEntireString) { (paragraphRange, _) in
            let paragraph = attrString.attributedSubstring(from: paragraphRange)
            let children = createNodes(fromParagraph: paragraph)

            let left = rightMostParagraphStyleElements(from: previous)
            let right = leftMostParagraphStyleElements(from: children)

            guard !merge(left: left, right: right) else {
                return
            }
            nodes += children
            previous = children
        }

        return RootNode(children: nodes)
    }


    ///
    ///
    private func createNodes(fromParagraph paragraph: NSAttributedString) -> [Node] {
        var children = [Node]()

        guard paragraph.length > 0 else {
            return []
        }

        paragraph.enumerateAttributes(in: paragraph.rangeOfEntireString, options: []) { (attrs, range, _) in

            let substring = paragraph.attributedSubstring(from: range)
            let leaves = createLeafNodes(from: substring)
            let nodes = createStyleNodes(from: attrs, leaves: leaves)

            children.append(contentsOf: nodes)
        }

        guard let paragraphElement = createParagraphElement(from: paragraph, children: children) else {
            return children
        }

        return [paragraphElement]
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
    func rightMostParagraphStyleElements(from nodes: [Node]) -> [ElementNode] {
        return paragraphStyleElements(from: nodes) { children in
            return children.last
        }
    }


    ///
    ///
    func leftMostParagraphStyleElements(from nodes: [Node]) -> [ElementNode] {
        return paragraphStyleElements(from: nodes) { children in
            return children.first
        }
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


    ///
    ///
    private func paragraphStyleElements(from nodes: [Node], childPicker: (([Node]) -> Node?)) -> [ElementNode] {
        var elements = [ElementNode]()
        var nextElement = childPicker(nodes) as? ElementNode


        while let currentElement = nextElement {
            guard currentElement.isBlockLevelElement() else {
                break
            }

            elements.append(currentElement)
            nextElement = childPicker(currentElement.children) as? ElementNode
        }

        return elements
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
    func createParagraphElement(from attrString: NSAttributedString, children: [Node]) -> ElementNode? {
        guard let paragraphStyle = attrString.attribute(NSParagraphStyleAttributeName, at: 0, effectiveRange: nil) as? ParagraphStyle else {
            return nil
        }

        var lastNodes: [ElementNode]?

        enumerateParagraphNodes(in: paragraphStyle) { node in
            node.children = lastNodes ?? children
            lastNodes = [node]
        }

        return lastNodes?.first
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

        switch attachment {
        case let lineAttachment as LineAttachment:
            return lineAttachmentToNodes(lineAttachment)
        case let commentAttachment as CommentAttachment:
            return commentAttachmentToNodes(commentAttachment)
        case let htmlAttachment as HTMLAttachment:
            return htmlAttachmentToNode(htmlAttachment)
        case let imageAttachment as ImageAttachment:
            return imageAttachmentToNodes(imageAttachment)
        default:
            return textToNodes(attrString.string)
        }
    }
}


// MARK: - Style Extraction
//
private extension NSAttributedStringToNodes {

    ///
    ///
    func enumerateParagraphNodes(in style: ParagraphStyle, block: ((ElementNode) -> Void)) {
        if style.blockquote != nil {
            let node = ElementNode(type: .blockquote)
            block(node)
        }

        if style.htmlParagraph != nil {
            let node = ElementNode(type: .p)
            block(node)
        }

        if style.headerLevel > 0 {
            let type = DOMString.elementTypeForHeaderLevel(style.headerLevel) ?? .h1
            let node = ElementNode(type: type)
            block(node)
        }

        if !style.textLists.isEmpty {
            let node = ElementNode(type: .li)
            block(node)
        }

        for list in style.textLists {
            let node = list.style == .ordered ? ElementNode(type: .ol) : ElementNode(type: .ul)
            block(node)
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
                    let node = ElementNode(type: .b)
                    block(node)
                }

                if font.containsTraits(.traitItalic) == true {
                    let node = ElementNode(type: .i)
                    block(node)
                }

            case NSLinkAttributeName:
                guard let url = value as? URL else {
                    break
                }

                let source = StringAttribute(name: "href", value: url.absoluteString)
                let node = ElementNode(type: .a, attributes: [source])
                block(node)

            case NSStrikethroughStyleAttributeName:
                let node = ElementNode(type: .strike)
                block(node)

            case NSUnderlineStyleAttributeName:
                let node = ElementNode(type: .u)
                block(node)

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
    func lineAttachmentToNodes(_ lineAttachment: LineAttachment) -> [Node] {
        let node = ElementNode(type: .hr)
        return [node]
    }


    ///
    ///
    func commentAttachmentToNodes(_ attachment: CommentAttachment) -> [Node] {
        let node = CommentNode(text: attachment.text)
        return [node]
    }


    ///
    ///
    func htmlAttachmentToNode(_ attachment: HTMLAttachment) -> [Node] {
        let converter = Libxml2.In.HTMLConverter()

        guard let rootNode = try? converter.convert(attachment.rawHTML),
            let firstChild = rootNode.children.first
        else {
            return textToNodes(attachment.rawHTML)
        }

        guard rootNode.children.count == 1 else {
            let node = ElementNode(type: .span, attributes: [], children: rootNode.children)
            return [node]
        }

        return [firstChild]
    }


    ///
    ///
    func imageAttachmentToNodes(_ attachment: ImageAttachment) -> [Node] {
        var attributes = [Attribute]()
        if let source = attachment.url?.absoluteString {
            let attribute = StringAttribute(name: "src", value: source)
            attributes.append(attribute)
        }

        let node = ElementNode(type: .img, attributes: attributes)
        return [node]
    }


    ///
    ///
    func textToNodes(_ text: String) -> [Node] {
        let substrings = text.components(separatedBy: String(.newline))
        var output = [Node]()

        for substring in substrings {
            if output.count > 0 {
                let newline = ElementNode(type: .br)
                output.append(newline)
            }

            let node = TextNode(text: substring)
            output.append(node)
        }
        
        return output
    }
}
