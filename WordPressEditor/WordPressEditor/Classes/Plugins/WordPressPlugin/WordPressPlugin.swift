import Aztec
import UIKit

/// WordPress Plugin for Aztec.
///
open class WordPressPlugin: Plugin {
    
    typealias GutenbergContentVerifier = (String) -> Bool
    
    public init() {
        let isGutenbergContent: GutenbergContentVerifier = { content -> Bool in
            return content.contains("<!-- wp:")
        }
        
        super.init(
            inputCustomizer: WordPressInputCustomizer(gutenbergContentVerifier: isGutenbergContent),
            outputCustomizer: WordPressOutputCustomizer(gutenbergContentVerifier: isGutenbergContent))
    }

    open override func loaded(textView: TextView) {
        textView.pasteboardDelegate = WordPressTextViewPasteboardDelegate()
    }
}
