import UIKit

class BRInserter: Inserter {
    func specialString(for element: ElementNode) -> String {
        return String(.lineSeparator)
    }
}
