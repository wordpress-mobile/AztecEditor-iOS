import Foundation
import UIKit

extension UITextView {
    
    /// Notifies the delegate of a text change.
    ///
    final func notifyTextViewDidChange() {
        delegate?.textViewDidChange?(self)
        NotificationCenter.default.post(name: .UITextViewTextDidChange, object: self)
    }
}
