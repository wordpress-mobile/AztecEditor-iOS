import Foundation

/// Maps HTML-Elements to control-character-elements.  This class is one of the few tasked with
/// abstracting control-characters from HTML.
///
class HTMLElementToControlledElementMapper {

    func map(_ nodeName: String) -> ControlledElement? {

        guard let elementType = Libxml2.StandardElementType(rawValue: nodeName) else {
            return nil
        }

        return map(elementType)
    }

    func map(_ elementType: Libxml2.StandardElementType) -> ControlledElement? {
        switch (elementType) {
        case .blockquote:
            return .blockquote
        case .li:
            return .listItem
        case .p:
            return .paragraph
        default:
            return nil
        }
    }
}
