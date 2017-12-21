import UIKit


/// Returns a specialised representation for a `<hr>` element.
///
class HRElementConverter: ElementConverter {

    func attachment(from representation: HTMLRepresentation, inheriting attributes: [AttributedStringKey : Any]) -> NSTextAttachment? {
        return LineAttachment()
    }

    func specialString(for element: ElementNode, inheriting attributes: [AttributedStringKey: Any]) -> NSAttributedString {
        return NSAttributedString(.textAttachment, attributes: attributes)
    }

    func extraAttributes(for representation: HTMLRepresentation, inheriting attributes: [AttributedStringKey: Any]) -> [AttributedStringKey : Any]? {
        return [.hrHtmlRepresentation: representation]
    }

    func canConvert(element: ElementNode) -> Bool {
        return element.standardName == .hr
    }
}
