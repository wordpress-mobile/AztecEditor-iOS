import Foundation
import UIKit

extension UITextView {
    
    /// Notifies the delegate of a text change.
    ///
    final func notifyTextViewDidChange() {
        if let textView = self as? TextView, !textView.shouldNotifyOfNonUserChanges {
            return
        }
        delegate?.textViewDidChange?(self)
        NotificationCenter.default.post(name: UITextView.textDidChangeNotification, object: self)
    }
}
