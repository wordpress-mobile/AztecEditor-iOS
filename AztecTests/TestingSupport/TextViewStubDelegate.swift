import Foundation
import Aztec
import UIKit


// MARK: - Wraps UITextView Delegate methods into callbacks, for Unit Testing purposes.
//
class TextViewStubDelegate: NSObject {

    /// Closure to be executed whenever `textViewDidChange` is executed.
    ///
    var onDidChange: (() -> Void)?

}


extension TextViewStubDelegate: UITextViewDelegate {

    func textViewDidChange(_ textView: UITextView) {
        onDidChange?()
    }
}
