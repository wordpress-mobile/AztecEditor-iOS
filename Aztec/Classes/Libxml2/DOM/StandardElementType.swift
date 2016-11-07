import Foundation
import UIKit

extension Libxml2 {
    /// This enum provides a list of HTML5 standard element names.  The reason why this isn't
    /// used as the `name` property of `ElementNode` is that element nodes could theoretically
    /// have non-standard names.
    ///
    enum StandardElementType: String {
        case a = "a"
        case address = "address"
        case b = "b"
        case br = "br"
        case blockquote = "blockquote"
        case dd = "dd"
        case del = "del"
        case div = "div"
        case dl = "dl"
        case dt = "dt"
        case em = "em"
        case fieldset = "fieldset"
        case form = "form"
        case h1 = "h1"
        case h2 = "h2"
        case h3 = "h3"
        case h4 = "h4"
        case h5 = "h5"
        case h6 = "h6"
        case hr = "hr"
        case i = "i"
        case img = "img"
        case li = "li"
        case noscript = "noscript"
        case ol = "ol"
        case p = "p"
        case pre = "pre"
        case s = "s"
        case strike = "strike"
        case strong = "strong"
        case table = "table"
        case tbody = "tbody"
        case td = "td"
        case tfoot = "tfoot"
        case th = "th"
        case thead = "thead"
        case tr = "tr"
        case u = "u"
        case ul = "ul"

        /// Returns an array with all block-level elements.
        ///
        static var blockLevelNodeNames: [StandardElementType] {
            return [.address, .blockquote, .div, .dl, .fieldset, .form, .h1, .h2, .h3, .h4, .h5, .h6,.hr, .noscript, .ol, .p, .pre, .table, .ul]
        }

        static func isBlockLevelNodeName(name: String) -> Bool {
            return StandardElementType(rawValue: name)?.isBlockLevelNodeName() ?? false
        }

        func isBlockLevelNodeName() -> Bool {
            return self.dynamicType.blockLevelNodeNames.contains(self)
        }

        /// Some nodes have a default representation that needs to be taken in account when checking the length
        ///
        func defaultVisualRepresentation() -> String? {
            switch self {
            case .img:
                return String(UnicodeScalar(NSAttachmentCharacter))
            case .br:
                return String("\n")
            default:
                return nil
            }
        }

        var equivalentNames: [String] {
            get {
                switch self {
                case .b: return [self.rawValue, StandardElementType.strong.rawValue]
                case .i: return [self.rawValue, StandardElementType.em.rawValue]
                case .s: return [self.rawValue, StandardElementType.strike.rawValue, StandardElementType.del.rawValue]
                default:
                    return [self.rawValue]
                }
            }
        }


    }
}
