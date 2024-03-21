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
        guard textView.pasteboard.hasURLs,
            let url = textView.pasteboard.url else {
                return false
        }

        let selectedRange = textView.selectedRange

        if selectedRange.length == 0 {
            guard textView.shouldChangeText(in: selectedRange, with: url.absoluteString) else {
                return true
            }
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
        guard let html = textView.pasteboard.html(),
            textView.storage.htmlConverter.isSupported(html) else {
                return false
        }
        let string = textView.storage.htmlConverter.attributedString(from: html)
        guard textView.shouldChangeText(in: textView.selectedRange, with: string.string) else {
            return true
        }

        textView.replace(textView.selectedRange, withHTML: html)
        return true
    }

    /// Tries to paste an attributed string from the clipboard as source, replacing the selected range.
    ///
    /// - Returns: True if the paste succeeds, false if it does not.
    ///
    open func tryPastingAttributedString(in textView: TextView) -> Bool {
        guard let string = textView.pasteboard.attributedString() else {
            return false
        }
        string.loadLazyAttachments()
        let selectedRange = textView.selectedRange

        guard textView.shouldChangeText(in: selectedRange, with: string.string) else {
            return true
        }

        let storage = textView.storage

        let finalRange = NSRange(location: selectedRange.location, length: string.length)
        let originalText = textView.attributedText.attributedSubstring(from: selectedRange)

        textView.undoManager?.registerUndo(withTarget: textView, handler: { [weak textView] target in
            textView?.undoTextReplacement(of: originalText, finalRange: finalRange)
        })

        let colorCorrectedString = fixColors(in: string, using: textView.defaultTextColor)

        storage.replaceCharacters(in: selectedRange, with: colorCorrectedString)
        textView.notifyTextViewDidChange()

        let newSelectedRange = NSRange(location: selectedRange.location + string.length, length: 0)
        textView.selectedRange = newSelectedRange

        return true
    }

    private func fixColors(in string: NSAttributedString, using baseColor: UIColor?) -> NSAttributedString {
        guard #available(iOS 13.0, *) else {
            return string
        }
        let colorToUse = baseColor ?? UIColor.label

        let newString = NSMutableAttributedString(attributedString: string)
        newString.enumerateAttributes(in: newString.rangeOfEntireString, options: []) { (attributes, range, stop) in
            if attributes[.foregroundColor] == nil {
                newString.setAttributes([.foregroundColor: colorToUse], range: range)
            }
        }
        return newString
    }

    /// Tries to paste raw text from the clipboard, replacing the selected range.
    ///
    /// - Returns: True if the paste succeeds, false if it does not.
    ///
    open func tryPastingString(in textView: TextView) -> Bool {
        guard let string = textView.pasteboard.attributedString() else {
            return false
        }

        let selectedRange = textView.selectedRange

        guard textView.shouldChangeText(in: selectedRange, with: string.string) else {
            return true
        }

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
