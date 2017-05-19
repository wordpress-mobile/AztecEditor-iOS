import Foundation
import UIKit
import libxml2



// MARK: - StylesEnumerator
//
extension Libxml2 {

    //
    //
    enum DOMParagraphStyle {
        case blockquote
        case paragraph
        case orderedList
        case unorderedList
        case header1
        case header2
        case header3
        case header4
        case header5
        case header6
        case horizontalRule
        case preformatted

        func toNode(children: [Node]) -> ElementNode {
            switch self {
            case .blockquote:
                return ElementNode(type: .blockquote, children: children)
            case .orderedList:
                return ElementNode(type: .ol, children: children)
            case .paragraph:
                return ElementNode(type: .p, children: children)
            case .unorderedList:
                return ElementNode(type: .ul, children: children)
            case .header1:
                return ElementNode(type: .h1, children: children)
            case .header2:
                return ElementNode(type: .h2, children: children)
            case .header3:
                return ElementNode(type: .h3, children: children)
            case .header4:
                return ElementNode(type: .h4, children: children)
            case .header5:
                return ElementNode(type: .h5, children: children)
            case .header6:
                return ElementNode(type: .h6, children: children)
            case .horizontalRule:
                return ElementNode(type: .hr, children: children)
            case .preformatted:
                return ElementNode(type: .pre, children: children)
            }
        }
    }

    //
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
                return ElementNode(type: .a, attributes: [source])
            case .bold:
                return ElementNode(type: .b)
            case .italics:
                return ElementNode(type: .i)
            case .image(let url):
                let source = StringAttribute(name: "src", value: url)
                return ElementNode(type: .img, attributes: [source])
            case .strike:
                return ElementNode(type: .strike)
            case .underlined:
                return ElementNode(type: .u)
            }
        }
    }


    ///
    ///
    class DOMStylesEnumerator {

        ///
        ///
        func styles(in attrString: NSAttributedString) -> ([DOMParagraphStyle], [DOMStyle]) {
            var paragraphStyles = [DOMParagraphStyle]()
            var styles = [DOMStyle]()

            attrString.enumerateAttributes(in: attrString.rangeOfEntireString, options: []) { (attrs, range, _) in

                for (key, value) in attrs {

                    paragraphStyles.append(contentsOf: self.paragraphStyles(key: key, value: value))
                    styles.append(contentsOf: self.styles(key: key, value: value))
                }
            }

            return (paragraphStyles, styles)
        }


        ///
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


            case NSFontAttributeName:
                break
            case NSAttachmentAttributeName:
                break
            default:
                break
            }

            return styles
        }

        ///
        ///
        func styles(key: String, value: Any) -> [DOMStyle] {
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
                break
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
