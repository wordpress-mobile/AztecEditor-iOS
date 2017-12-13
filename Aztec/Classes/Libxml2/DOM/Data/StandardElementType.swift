import Foundation
import UIKit


/// This enum provides a list of HTML5 standard element names.  The reason why this isn't
/// used as the `name` property of `ElementNode` is that element nodes could theoretically
/// have non-standard names.
///
public enum StandardElementType: String {
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
    case figure = "figure"
    case figcaption = "figcaption"
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
    case span = "span"
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
    case video = "video"

    /// Returns an array with all block-level elements.
    ///
    static var blockLevelNodeNames: [StandardElementType] {
        return [.address, .blockquote, .div, .dl, .fieldset, .form, .h1, .h2, .h3, .h4, .h5, .h6, .hr, .li, .noscript, .ol, .p, .pre, .table, .tr, .td, .ul, .figcaption, .figure]
    }

    static func isBlockLevelNodeName(_ name: String) -> Bool {
        return StandardElementType(rawValue: name)?.isBlockLevelNodeName() ?? false
    }

    func isBlockLevelNodeName() -> Bool {
        return type(of: self).blockLevelNodeNames.contains(self)
    }

    var equivalentNames: [String] {
        get {
            switch self {
            case .h1: return [self.rawValue]
            case .strong: return [self.rawValue, StandardElementType.b.rawValue]
            case .em: return [self.rawValue, StandardElementType.i.rawValue]
            case .b: return [self.rawValue, StandardElementType.strong.rawValue]
            case .i: return [self.rawValue, StandardElementType.em.rawValue]
            case .s: return [self.rawValue, StandardElementType.strike.rawValue, StandardElementType.del.rawValue]
            case .del: return [self.rawValue, StandardElementType.strike.rawValue, StandardElementType.s.rawValue]
            case .strike: return [self.rawValue, StandardElementType.del.rawValue, StandardElementType.s.rawValue]
            default:
                return [self.rawValue]
            }
        }
    }    
}
