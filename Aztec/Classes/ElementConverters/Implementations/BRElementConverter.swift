import UIKit


/// Converts `<br>` elements into a `String(.lineSeparator)`.
///
class BRElementConverter: ElementConverter {
    func specialString(for element: ElementNode, inheriting attributes: [AttributedStringKey: Any]) -> NSAttributedString {
        return NSAttributedString(.lineSeparator, attributes: attributes)
    }

    func canConvert(element: ElementNode) -> Bool {
        return element.standardName == .br
    }
}
