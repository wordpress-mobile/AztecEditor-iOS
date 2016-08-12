import UIKit

/// A helper extension for UITextView.
///
extension UITextView
{

    /// A convenience metod for getting the CGRect of the currentl text selection.
    ///
    /// - Returns: The CGRect of the current text selection.
    ///
    public func rectForCurrentSelection() -> CGRect {
        return layoutManager.boundingRectForGlyphRange(selectedRange, inTextContainer: textContainer)
    }
}
