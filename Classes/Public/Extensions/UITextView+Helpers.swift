import UIKit

/// A helper extension for UITextView.
///
extension UITextView
{
    /// A convenience metod for getting the CGRect of the current text selection.
    ///
    public func rectForCurrentSelection() -> CGRect {
        return layoutManager.boundingRectForGlyphRange(selectedRange, inTextContainer: textContainer)
    }


    /// Determines what's the position of the cursor, expressed as the character index we're currently at.
    ///
    public func positionForCursor() -> Int {
        guard let selectedRange = selectedTextRange else {
            return 0
        }

        return offsetFromPosition(beginningOfDocument, toPosition: selectedRange.start)
    }

    /// Determines the frame occupied onscreen by a given range.
    ///
    func frameForTextInRange(range: NSRange) -> CGRect {
        guard let firstPosition = positionFromPosition(beginningOfDocument, offset: range.location),
            let lastPosition = positionFromPosition(beginningOfDocument, offset: range.location + range.length),
            let textRange = textRangeFromPosition(firstPosition, toPosition: lastPosition) else
        {
            return CGRectZero
        }

        return firstRectForRange(textRange)
    }
}
