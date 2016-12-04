import UIKit

/// A helper extension for UITextView.
///
extension UITextView
{
    /// A convenience metod for getting the CGRect of the current text selection.
    ///
    public func rectForCurrentSelection() -> CGRect {
        return layoutManager.boundingRect(forGlyphRange: selectedRange, in: textContainer)
    }


    /// Determines what's the position of the cursor, expressed as the character index we're currently at.
    ///
    public func positionForCursor() -> Int {
        guard let selectedRange = selectedTextRange else {
            return 0
        }

        return offset(from: beginningOfDocument, to: selectedRange.start)
    }

    /// Determines the frame occupied onscreen by a given range.
    ///
    func frameForTextInRange(_ range: NSRange) -> CGRect {
        guard let firstPosition = position(from: beginningOfDocument, offset: range.location),
            let lastPosition = position(from: beginningOfDocument, offset: range.location + range.length),
            let textRange = textRange(from: firstPosition, to: lastPosition) else
        {
            return .zero
        }

        return firstRect(for: textRange)
    }
}
