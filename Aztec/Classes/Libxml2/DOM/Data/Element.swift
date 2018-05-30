import Foundation
import UIKit

/// This enum provides a list of HTML5 standard element names.  The reason why this isn't
/// used as the `name` property of `ElementNode` is that element nodes could theoretically
/// have non-standard names.
///
public struct Element: RawRepresentable, Hashable {
    
    public typealias RawValue = String
    
    public let rawValue: String
    
    /// This can be extended in case new elements need to be defined.
    ///
    public static var blockLevelElements: [Element] = [.address, .aztecRootNode, .blockquote, .div, .dl, .dd, .dt, .fieldset, .figure, .figcaption, .form, .h1, .h2, .h3, .h4, .h5, .h6, .hr, .li, .noscript, .ol, .p, .pre, .table, .td, .tr, .ul]
    
    // MARK: - Initializers
    
    public init?(rawValue: RawValue) {
        self.init(rawValue)
    }
    
    public init(_ rawValue: RawValue) {
        self.rawValue = rawValue
    }
    
    public func isBlockLevel() -> Bool {
        return Element.blockLevelElements.contains(self)
    }
}

extension Element {
    static let aztecRootNode = Element("aztec.htmltag.rootnode")
}

/// Standard HTML 5 elements
///
extension Element {
    public static let a = Element("a")
    public static let address = Element("address")
    public static let b = Element("b")
    public static let br = Element("br")
    public static let blockquote = Element("blockquote")
    public static let dd = Element("dd")
    public static let del = Element("del")
    public static let div = Element("div")
    public static let dl = Element("dl")
    public static let dt = Element("dt")
    public static let em = Element("em")
    public static let fieldset = Element("fieldset")
    public static let figure = Element("figure")
    public static let figcaption = Element("figcaption")
    public static let form = Element("form")
    public static let h1 = Element("h1")
    public static let h2 = Element("h2")
    public static let h3 = Element("h3")
    public static let h4 = Element("h4")
    public static let h5 = Element("h5")
    public static let h6 = Element("h6")
    public static let hr = Element("hr")
    public static let i = Element("i")
    public static let img = Element("img")
    public static let li = Element("li")
    public static let noscript = Element("noscript")
    public static let ol = Element("ol")
    public static let p = Element("p")
    public static let pre = Element("pre")
    public static let s = Element("s")
    public static let span = Element("span")
    public static let strike = Element("strike")
    public static let strong = Element("strong")
    public static let table = Element("table")
    public static let tbody = Element("tbody")
    public static let td = Element("td")
    public static let tfoot = Element("tfoot")
    public static let th = Element("th")
    public static let thead = Element("thead")
    public static let tr = Element("tr")
    public static let u = Element("u")
    public static let ul = Element("ul")
    public static let video = Element("video")
    public static let code = Element("code")
    public static let cite = Element("cite")

}

extension Element {
    static func isBlockLevelElement(_ name: String) -> Bool {
        return Element(name).isBlockLevel()
    }

    var equivalentNames: [String] {
        get {
            switch self {
            case .h1: return [self.rawValue]
            case .strong: return [self.rawValue, Element.b.rawValue]
            case .em: return [self.rawValue, Element.i.rawValue]
            case .b: return [self.rawValue, Element.strong.rawValue]
            case .i: return [self.rawValue, Element.em.rawValue]
            case .s: return [self.rawValue, Element.strike.rawValue, Element.del.rawValue]
            case .del: return [self.rawValue, Element.strike.rawValue, Element.s.rawValue]
            case .strike: return [self.rawValue, Element.del.rawValue, Element.s.rawValue]
            default:
                return [self.rawValue]
            }
        }
    }    
}
