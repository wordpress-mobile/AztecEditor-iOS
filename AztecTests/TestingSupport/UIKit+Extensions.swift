import UIKit

extension UIPasteboard {
    static let forTesting = UIPasteboard.withUniqueName()

    /// Remove all items from the pasteboard
    ///
    func reset() {
        self.items = [[:]]
    }
}
