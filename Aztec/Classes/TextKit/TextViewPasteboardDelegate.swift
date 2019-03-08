import UIKit

open class AztecTextViewPasteboardDelegate: TextViewPasteboardDelegate {

    public init() {}

    /// Tries to paste whatever is on the pasteboard into the editor.
    ///
    /// - Returns: True if the paste succeeds, false if it does not.
    ///
    open func tryPasting(in textView: TextView) -> Bool {
        return tryPastingURL(in: textView)
            || tryPastingHTML(in: textView)
            || tryPastingAttributedString(in: textView)
            || tryPastingString(in: textView)
    }

    /// Tries to paste a URL from the clipboard as a link applied to the selected range.
    ///
    /// - Returns: True if the paste succeeds, false if it does not.
    ///
    open func tryPastingURL(in textView: TextView) -> Bool {
        guard UIPasteboard.general.hasURLs,
            let url = UIPasteboard.general.url else {
                return false
        }

        let selectedRange = textView.selectedRange

        if selectedRange.length == 0 {
            textView.setLink(url, title:url.absoluteString, inRange: selectedRange)
        } else {
            textView.setLink(url, inRange: selectedRange)
        }

        return true
    }
    
    /// Tries to paste HTML from the clipboard as source, replacing the selected range.
    ///
    /// - Returns: True if the paste succeeds, false if it does not.
    ///
    open func tryPastingHTML(in textView: TextView) -> Bool {
        guard let html = UIPasteboard.general.html(),
            textView.storage.htmlConverter.isSupported(html) else {
                return false
        }

        textView.replace(textView.selectedRange, withHTML: html)
        return true
    }

    /// Tries to paste an attributed string from the clipboard as source, replacing the selected range.
    ///
    /// - Returns: True if the paste succeeds, false if it does not.
    ///
    open func tryPastingAttributedString(in textView: TextView) -> Bool {
        guard let string = UIPasteboard.general.attributedString() else {
            return false
        }

        let selectedRange = textView.selectedRange
        let storage = textView.storage

        let finalRange = NSRange(location: selectedRange.location, length: string.length)
        let originalText = textView.attributedText.attributedSubstring(from: selectedRange)

        textView.undoManager?.registerUndo(withTarget: textView, handler: { [weak textView] target in
            textView?.undoTextReplacement(of: originalText, finalRange: finalRange)
        })

        string.loadLazyAttachments()

        storage.replaceCharacters(in: selectedRange, with: string)
        textView.notifyTextViewDidChange()

        let newSelectedRange = NSRange(location: selectedRange.location + string.length, length: 0)
        textView.selectedRange = newSelectedRange

        return true
    }

    /// Tries to paste raw text from the clipboard, replacing the selected range.
    ///
    /// - Returns: True if the paste succeeds, false if it does not.
    ///
    open func tryPastingString(in textView: TextView) -> Bool {
        guard let string = UIPasteboard.general.attributedString() else {
            return false
        }

        let selectedRange = textView.selectedRange
        let finalRange = NSRange(location: selectedRange.location, length: string.length)
        let originalText = textView.attributedText.attributedSubstring(from: selectedRange)

        textView.undoManager?.registerUndo(withTarget: textView, handler: { [weak textView] target in
            textView?.undoTextReplacement(of: originalText, finalRange: finalRange)
        })

        let newString = NSMutableAttributedString(attributedString: string)

        string.enumerateAttributes(in: string.rangeOfEntireString, options: []) { (attributes, range, stop) in
            let newAttributes = attributes.filter({ (key, value) -> Bool in
                return value is NSTextAttachment
            })

            newString.setAttributes(newAttributes, range: range)
        }

        newString.addAttributes(textView.typingAttributes, range: string.rangeOfEntireString)
        newString.loadLazyAttachments()

        textView.storage.replaceCharacters(in: selectedRange, with: newString)
        textView.notifyTextViewDidChange()

        let newSelectedRange = NSRange(location: selectedRange.location + newString.length, length: 0)
        textView.selectedRange = newSelectedRange

        return true
    }
}
