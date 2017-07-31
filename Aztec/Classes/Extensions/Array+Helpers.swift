import Foundation


// MARK: - Array Helpers
//
extension Array {

    /// Returns the last Element Index within the current collection, that satisfies the specified closure.
    ///
    func lastIndex(where block: ((Element) -> Bool)) -> Int? {
        for (index, element) in enumerated().reversed() where block(element) {
            return index
        }

        return nil
    }
}
