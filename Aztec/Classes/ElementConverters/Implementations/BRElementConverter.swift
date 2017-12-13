import UIKit


/// Converts `<br>` elements into a `String(.lineSeparator)`.
///
class BRElementConverter: ElementConverter {
    func specialString(for element: ElementNode) -> String {
        return String(.lineSeparator)
    }

    func canConvert(element: ElementNode) -> Bool {
        return element.standardName == .br
    }
}
