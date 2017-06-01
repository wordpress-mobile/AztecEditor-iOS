import Foundation
import UIKit
import libxml2


// MARK: - StylesEnumerator
//
extension Libxml2 {

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
                let header = DOMString.elementTypeForHeaderLevel(level) ?? .h1
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


    // MARK: - NSAttributedStringToNodes
    //
    class NSAttributedStringToNodes {

        ///
        ///
        func createNodes(from attrString: NSAttributedString) -> [Node] {

            var result = [Node]()

            attrString.enumerateParagraphs(spanning: attrString.rangeOfEntireString) { (_, subString) in
                let node = createNode(from: subString)

                result.append(node)
            }

            return result
        }

        ///
        ///
        private func createNode(from attrString: NSAttributedString) -> Node {

            let paragraphElement = createParagraphElement(from: attrString)
            let (lastParagraphElement, _) = DOMInspector().findLeftmostLowestDescendantElement(of: paragraphElement, intersecting: 0)

            attrString.enumerateAttributes(in: attrString.rangeOfEntireString, options: []) { (attrs, range, _) in

                let styles = attributesToStyles(attributes: attrs)
                let leaves = leafNodes(from: attrString.attributedSubstring(from: range))
                let nodes = createNodes(from: styles, leaves: leaves)

                for node in nodes {
                    lastParagraphElement.children.append(node)
                    node.parent = lastParagraphElement
                }
            }

            return paragraphElement
        }

        // MARK: - Leaf Nodes

        ///
        ///
        private func leafNodes(from attrString: NSAttributedString) -> [Node] {
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


        // MARK: - Node Creation

        private func createParagraphElement(from attrString: NSAttributedString) -> ElementNode {

            guard let paragraphStyle = attrString.attribute(NSParagraphStyleAttributeName, at: 0, effectiveRange: nil) as? ParagraphStyle else {
                return ElementNode(type: .p, children: [])
            }

            return createElement(from: paragraphStyle)
        }

        private func createElement(from paragraphStyle: ParagraphStyle) -> ElementNode {
            let domParagraphStyles = self.domParagraphStyles(from: paragraphStyle)
            return createElement(from: domParagraphStyles)
        }

        /// Creates a node from an array of `DOMParagraphStyle` objects.
        ///
        /// - Parameters:
        ///     - domParagraphStyles: the input DOM paragraph styles to create the nodes from.
        ///
        /// - Returns: the requested node.
        ///
        private func createElement(from domParagraphStyles: [DOMParagraphStyle]) -> ElementNode {

            assert(domParagraphStyles.count > 0)

            let element = domParagraphStyles.reversed().reduce(nil) { (previous, style) -> ElementNode in

                guard let previous = previous else {
                    return style.toElement(children: [])
                }

                return style.toElement(children: [previous])
            }

            guard let result = element else {
                fatalError("The input array of paragraph styles cannot be empty, so this should not be possible.")
            }

            return result
        }

        ///
        ///
        private func createNodes(from domStyles: [DOMStyle], leaves: [Node]) -> [Node] {
            let styleNodes = domStyles.reversed().reduce(leaves) { (children, style) in
                return [style.toNode(children: children)]
            }

            return styleNodes
        }


        // MARK: - Style Extraction

        ///
        ///
        private func attributesToStyles(attributes: [String: Any]) -> [DOMStyle] {
            var styles = [DOMStyle]()

            for (key, value) in attributes {
                styles.append(contentsOf: self.styles(key: key, value: value))
            }

            return styles
        }


        /// Converts a NSAttributedString Attribute / Value into an array of DOMParagraphStyle Instances.
        ///
        private func domParagraphStyles(from style: ParagraphStyle) -> [DOMParagraphStyle] {
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

            for list in style.textLists {
                if list.style == .ordered {
                    styles.append(.orderedList)
                } else {
                    styles.append(.unorderedList)
                }
            }

            guard styles.isEmpty == false else {
                return [DOMParagraphStyle.paragraph]
            }

            return styles
        }


        /// Converts a NSAttributedString Attribute / Value into an array of DOMStyle Instances.
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
}
