import UIKit
import Aztec

class WordPressTextViewPasteboardDelegate: AztecTextViewPasteboardDelegate {

    override func tryPastingURL(in textView: TextView) -> Bool {

        let selectedRange = textView.selectedRange

        /// TODO: support pasting multiple URLs
        guard UIPasteboard.general.hasURLs,             // There are URLs on the pasteboard
            let url = UIPasteboard.general.url,         // We can get the first one
            selectedRange.length == 0,                  // No text is selected in the TextView
            EmbedURLProcessor(url: url).isValidEmbed    // The pasteboard contains an embeddable URL
            else {
                return super.tryPastingURL(in: textView)
        }

        let result = super.tryPastingString(in: textView)
        if result {
            // Bump the input to the next line – we need the embed link to be the only
            // text on this line – otherwise it can't be autoconverted.
            textView.insertText(String(.lineSeparator))
        }

        return result
    }
}
