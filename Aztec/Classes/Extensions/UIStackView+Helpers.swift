import Foundation
import UIKit


// MARK: - StackView Helpers
//
extension UIStackView {

    /// Adds a collection of arranged Subviews
    ///
    func addArrangedSubviews(_ subviews: [UIView]) {
        for subview in subviews {
            addArrangedSubview(subview)
        }
    }

    /// Removes a collection fo arranged subviews
    ///
    func removeArrangedSubviews(_ subviews: [UIView]) {
        for subview in subviews {
            removeArrangedSubview(subview)
        }
    }
}
