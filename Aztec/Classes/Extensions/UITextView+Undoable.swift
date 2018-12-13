import Foundation
import UIKit

extension UITextView {
    
    /// Replaces the specified range with the provided string.  Undoable.
    ///
    /// - Parameters:
    ///     - range: the range from the original string that will be replaced.
    ///     - string: the new string.
    ///
    public func replace(_ range: NSRange, with string: String) {
        
        let originalString = textStorage.attributedSubstring(from: range)
        let finalRange = NSRange(location: range.location, length: string.utf16.count)
        
        undoManager?.registerUndo(withTarget: self, handler: { target in
            target.undoTextReplacement(of: originalString, finalRange: finalRange)
        })
        
        textStorage.replaceCharacters(in: range, with: string)
        selectedRange = NSRange(location: finalRange.location + finalRange.length, length: 0)
        
        notifyTextViewDidChange()
    }

    /// Undoes a text replacement.  Undoable.
    ///
    /// - Parameters:
    ///     - originalText: the text that was there originally.
    ///     - finalRange: the range of the final string, that we'll roll back.
    ///
    public func undoTextReplacement(of originalText: NSAttributedString, finalRange: NSRange) {
        
        let redoOriginalText = textStorage.attributedSubstring(from: finalRange)
        let redoFinalRange = NSRange(location: finalRange.location, length: originalText.length)
        
        textStorage.replaceCharacters(in: finalRange, with: originalText)
        selectedRange = redoFinalRange
        
        undoManager?.registerUndo(withTarget: self, handler: { target in
            target.undoTextReplacement(of: redoOriginalText, finalRange: redoFinalRange)
        })
        
        notifyTextViewDidChange()
    }
}
