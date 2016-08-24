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


    /// Determines what's the position of the cursor, expressed as the character index we're currently at.
    ///
    /// - Returns: An integer indicating the current position.
    ///
    public func positionForCursor() -> Int {
        guard let selectedRange = selectedTextRange else {
            return 0
        }

        return offsetFromPosition(beginningOfDocument, toPosition: selectedRange.start)
    }
}
