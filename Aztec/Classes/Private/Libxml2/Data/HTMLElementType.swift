import Foundation
import UIKit

extension Libxml2 {
    /// This enum provides a list of HTML5 standard element names.  The reason why this isn't
    /// used as the `name` property of `ElementNode` is that element nodes could theoretically
    /// have non-standard names.
    ///
    enum HTMLElementType: String {
        case A = "a"
        case Address = "address"
        case B = "b"
        case Br = "br"
        case Blockquote = "blockquote"
        case Dd = "dd"
        case Del = "del"
        case Div = "div"
        case Dl = "dl"
        case Dt = "dt"
        case Em = "em"
        case Fieldset = "fieldset"
        case Form = "form"
        case H1 = "h1"
        case H2 = "h2"
        case H3 = "h3"
        case H4 = "h4"
        case H5 = "h5"
        case H6 = "h6"
        case Hr = "hr"
        case I = "i"
        case Img = "img"
        case Li = "li"
        case Noscript = "noscript"
        case Ol = "ol"
        case P = "p"
        case Pre = "pre"
        case S = "s"
        case Strike = "strike"
        case Strong = "strong"
        case Table = "table"
        case Tbody = "tbody"
        case Td = "td"
        case Tfoot = "tfoot"
        case Th = "th"
        case Thead = "thead"
        case Tr = "tr"
        case U = "u"
        case Ul = "ul"

        /// Returns an array with all block-level elements.
        ///
        static func blockLevelNodeNames() -> [HTMLElementType] {
            return [.Address, .Blockquote, .Div, .Dl, .Fieldset, .Form, .H1, .H2, .H3, .H4, .H5, .H6, .Hr, .Noscript, .Ol, .P, .Pre, .Table, .Ul]
        }

        static func isBlockLevelNodeName(name: String) -> Bool {
            return HTMLElementType(rawValue: name)?.isBlockLevelNodeName() ?? false
        }

        func isBlockLevelNodeName() -> Bool {
            return self.dynamicType.blockLevelNodeNames().contains(self)
        }

        /// Some nodes have a default representation that needs to be taken in account when checking the length
        ///
        func defaultVisualRepresentation() -> String? {
            switch self {
            case .Img:
                return String(UnicodeScalar(NSAttachmentCharacter))
            case .Br:
                return String("\n")
            default:
                return nil
            }
        }

        var equivalentNames: [String] {
            get {
                switch self {
                case .B: return [self.rawValue, HTMLElementType.Strong.rawValue]
                case .I: return [self.rawValue, HTMLElementType.Em.rawValue]
                case .S: return [self.rawValue, HTMLElementType.Strike.rawValue, HTMLElementType.Del.rawValue]
                default:
                    return [self.rawValue]
                }
            }
        }


    }
}
