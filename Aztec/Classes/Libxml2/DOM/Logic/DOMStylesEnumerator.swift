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

        func toNode(children: [Node]) -> ElementNode {
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
                let source = StringAttribute(name: "src", value: url)
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


    // MARK: - DOMStylesEnumerator
    //
    class DOMStylesEnumerator {

        ///
        ///
        func enumerateStyles(in attrString: NSAttributedString, using block: ((NSRange, Node) -> Void)) {
            attrString.enumerateAttributes(in: attrString.rangeOfEntireString, options: []) { (attrs, range, _) in

                let (paragraphStyles, styles) = attributesToStyles(attributes: attrs)
                let leaf = leafNode(from: attrString.attributedSubstring(from: range))
                let mainNode = stylesToNode(paragraphStyles: paragraphStyles, styles: styles, leaf: leaf)

                block(range, mainNode)
            }
        }

        ///
        ///
        private func leafNode(from attrString: NSAttributedString) -> Node {
            let attachment = attrString.attribute(NSAttachmentAttributeName, at: 0, effectiveRange: nil) as? NSTextAttachment

            switch attachment {
            case let lineAttachment as LineAttachment:
                return lineAttachmentToNode(lineAttachment)
            case let commentAttachment as CommentAttachment:
                return commentAttachmentToNode(commentAttachment)
            case let htmlAttachment as HTMLAttachment:
                return htmlAttachmentToNode(htmlAttachment)
            case let imageAttachment as ImageAttachment:
                return imageAttachmentToNode(imageAttachment)
            default:
                return textToNode(attrString.string)
            }
        }


        // MARK: - Leaf Node Helpers

        ///
        ///
        private func lineAttachmentToNode(_ lineAttachment: LineAttachment) -> ElementNode {
            return ElementNode(name: StandardElementType.hr.rawValue, attributes: [], children: [])
        }


        ///
        ///
        private func commentAttachmentToNode(_ attachment: CommentAttachment) -> CommentNode {
            return CommentNode(text: attachment.text)
        }


        ///
        ///
        private func htmlAttachmentToNode(_ attachment: HTMLAttachment) -> Node {
            let converter = Libxml2.In.HTMLConverter()

            guard let rootNode = try? converter.convert(attachment.rawHTML),
                let firstChild = rootNode.children.first
            else {
                return textToNode(attachment.rawHTML)
            }

            guard rootNode.children.count == 1 else {
                return ElementNode(name: StandardElementType.span.rawValue, attributes: [], children: rootNode.children)
            }

            return firstChild
        }


        ///
        ///
        private func imageAttachmentToNode(_ attachment: ImageAttachment) -> ElementNode {
            var attributes = [Attribute]()
            if let url = attachment.url {
                let source = StringAttribute(name: "src", value: url.absoluteString)
                attributes.append(source)
            }

            return ElementNode(name: StandardElementType.img.rawValue, attributes: attributes, children: [])
        }


        ///
        ///
        private func textToNode(_ text: String) -> TextNode {
            return TextNode(text: text)
        }


        // MARK: - Node Generation Helpers

        ///
        ///
        private func stylesToNode(paragraphStyles: [DOMParagraphStyle], styles: [DOMStyle], leaf: Node) -> Node {
            let stylesRoot = styles.reversed().reduce(leaf) { (result, style) -> Node in
                return style.toNode(children: [result])
            }

            let paragraphStylesRoot = paragraphStyles.reversed().reduce(stylesRoot) { (result, style) in
                return style.toNode(children: [result])
            }

            return paragraphStylesRoot
        }


        // MARK: - Style Extraction Helpers

        ///
        ///
        private func attributesToStyles(attributes: [String: Any]) -> ([DOMParagraphStyle], [DOMStyle]) {
            var paragraphStyles = [DOMParagraphStyle]()
            var styles = [DOMStyle]()

            for (key, value) in attributes {
                paragraphStyles.append(contentsOf: self.paragraphStyles(key: key, value: value))
                styles.append(contentsOf: self.styles(key: key, value: value))
            }

            return (paragraphStyles, styles)
        }


        /// Converts a NSAttributedString Attribute / Value into an array of DOMParagraphStyle Instances.
        ///
        private func paragraphStyles(key: String, value: Any) -> [DOMParagraphStyle] {
            var styles = [DOMParagraphStyle]()

            switch key {
            case NSParagraphStyleAttributeName:
                guard let paragraph = value as? ParagraphStyle else {
                    break
                }

                if paragraph.blockquote != nil {
                    styles.append(.blockquote)
                }

                if paragraph.htmlParagraph != nil {
                    styles.append(.paragraph)
                }

                if paragraph.headerLevel > 0 {
                    styles.append(.header(level: paragraph.headerLevel))
                }

                for list in paragraph.textLists {
                    if list.style == .ordered {
                        styles.append(.orderedList)
                    } else {
                        styles.append(.unorderedList)
                    }
                }

            case NSFontAttributeName:
                break
            case NSAttachmentAttributeName:
                break
            default:
                break
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
