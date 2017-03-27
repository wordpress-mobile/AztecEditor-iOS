import Foundation
import UIKit


// MARK: - NSAttributedString Analyzer Helpers
//
extension NSAttributedString {

    /// Returns true if the text preceding a given location contains the NSLinkAttribute.
    ///
    func isLocationPreceededByLink(_ location: Int) -> Bool {
        let beforeRange = NSRange(location: location - 1, length: 1)
        guard beforeRange.location >= 0 else {
            return false
        }

        return attribute(NSLinkAttributeName, at: beforeRange.location, effectiveRange: nil) != nil
    }

    /// Returns true if the text immediately succeding a given location contains the NSLinkAttribute.
    ///
    func isLocationSuccededByLink(_ location: Int) -> Bool {
        let afterRange = NSRange(location: location, length: 1)
        guard afterRange.endLocation < length else {
            return false
        }

        return attribute(NSLinkAttributeName, at: afterRange.location, effectiveRange: nil) != nil
    }
}
