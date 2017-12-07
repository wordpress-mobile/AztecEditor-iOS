import UIKit

class BRElementConverter: ElementConverter {
    func specialString(for element: ElementNode) -> String {
        return String(.lineSeparator)
    }
}
