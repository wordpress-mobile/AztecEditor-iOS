import Foundation

/// This enum specifies the different entities that can represent a style in HTML. 
///
enum HTMLRepresentation {
    case element(ElementNode)
    case attribute(Attribute)
    case inlineCss(CSSProperty)
}
