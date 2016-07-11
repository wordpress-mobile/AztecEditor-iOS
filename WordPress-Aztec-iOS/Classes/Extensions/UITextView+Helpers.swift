import UIKit

///
///
extension UITextView
{

    ///
    ///
    public func rectForCurrentSelection() -> CGRect {
        return layoutManager.boundingRectForGlyphRange(selectedRange, inTextContainer: textContainer)
    }

}
