import Foundation
import UIKit


// MARK: - NSAttributedString Analyzer Helpers
//
extension NSAttributedString {

    /// Returns true if the text preceding a given location contains the NSLinkAttribute.
    ///
    func isLocationPreceededByLink(_ location: Int) -> Bool {
        guard location != 0 else {
            return false
        }
        let beforeRange = NSRange(location: location - 1, length: 1)

        return attribute(.link, at: beforeRange.location, effectiveRange: nil) != nil
    }

    /// Returns true if the text immediately succeding a given location contains the NSLinkAttribute.
    ///
    func isLocationSuccededByLink(_ location: Int) -> Bool {
        let afterRange = NSRange(location: location, length: 1)
        guard afterRange.endLocation < length else {
            return false
        }

        return attribute(.link, at: afterRange.location, effectiveRange: nil) != nil
    }

    /// Returns the Substring at the specified range, whenever the received range is valid, or nil
    /// otherwise.
    ///
    func safeSubstring(at range: NSRange) -> String? {
        guard range.location >= 0 && range.endLocation <= length else {
            return nil
        }

        return attributedSubstring(from: range).string
    }
}
