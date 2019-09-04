import Foundation
import UIKit


// MARK: - NSTextStorage Implementation: Automatically colorizes all of the present HTML Tags.
//
open class HTMLStorage: NSTextStorage {

    /// Internal Storage
    ///
    private var textStore = NSMutableAttributedString(string: "", attributes: nil)
    fileprivate var textStoreString = ""

    /// Document's Font
    ///
    open var font: UIFont

    /// Color to be applied over HTML text
    ///
    open var textColor = Styles.defaultTextColor

    /// Color to be applied over HTML Comments
    ///
    open var commentColor = Styles.defaultCommentColor

    /// Color to be applied over HTML Tags
    ///
    open var tagColor = Styles.defaultTagColor

    /// Color to be applied over Quotes within HTML Tags
    ///
    open var quotedColor = Styles.defaultQuotedColor

    // MARK: - Initializers

    public override init() {
        // Note:
        // iOS 11 has changed the way Copy + Paste works. As far as we can tell, upon Paste, the system
        // instantiates a new UITextView stack, and renders it on top of the one in use.
        // This (appears) to be the cause of a glitch in which the pasted text would temporarily appear out
        // of phase, on top of the "pre paste UI".
        //
        // We're adding a ridiculosly small defaultFont here, in order to force the "Secondary" UITextView
        // not to render anything.
        //
        // Ref. https://github.com/wordpress-mobile/AztecEditor-iOS/issues/771
        //
        font = UIFont.systemFont(ofSize: 4)
        super.init()
    }

    public init(defaultFont: UIFont) {
        font = defaultFont
        super.init()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    required public init(itemProviderData data: Data, typeIdentifier: String) throws {
        fatalError("init(itemProviderData:typeIdentifier:) has not been implemented")
    }


    // MARK: - Overriden Methods

    override open var string: String {
        return textStoreString
    }
    
    private func replaceTextStoreString(_ range: NSRange, with string: String) {
        let utf16String = textStoreString.utf16
        let startIndex = utf16String.index(utf16String.startIndex, offsetBy: range.location)
        let endIndex = utf16String.index(startIndex, offsetBy: range.length)
        textStoreString.replaceSubrange(startIndex..<endIndex, with: string)
    }

    override open func attributes(at location: Int, effectiveRange range: NSRangePointer?) -> [NSAttributedString.Key : Any] {
        guard textStore.length != 0 else {
            return [:]
        }

        return textStore.attributes(at: location, effectiveRange: range)
    }

    override open func setAttributes(_ attrs: [NSAttributedString.Key : Any]?, range: NSRange) {
        beginEditing()

        textStore.setAttributes(attrs, range: range)
        edited(.editedAttributes, range: range, changeInLength: 0)

        endEditing()
    }

    override open func replaceCharacters(in range: NSRange, with str: String) {
        beginEditing()

        textStore.replaceCharacters(in: range, with: str)
        replaceTextStoreString(range, with: str)
        
        edited([.editedAttributes, .editedCharacters], range: range, changeInLength: str.utf16.count - range.length)
        
        colorizeHTML()
        endEditing()
    }

    override open func replaceCharacters(in range: NSRange, with attrString: NSAttributedString) {
        beginEditing()

        textStore.replaceCharacters(in: range, with: attrString)
        replaceTextStoreString(range, with: attrString.string)
        
        edited([.editedAttributes, .editedCharacters], range: range, changeInLength: attrString.length - range.length)
        
        colorizeHTML()
        endEditing()
    }
}


// MARK: - Private Helpers
//
private extension HTMLStorage {

    /// Colorizes all of the HTML Tags contained within this Storage
    ///
    func colorizeHTML() {
        let fullStringRange = rangeOfEntireString

        addAttribute(.foregroundColor, value: textColor, range: fullStringRange)
        addAttribute(.font, value: font, range: fullStringRange)

        let tags = RegExes.html.matches(in: string, options: [], range: fullStringRange)

        for tag in tags {
            addAttribute(.foregroundColor, value: tagColor, range: tag.range)

            let quotes = RegExes.quotes.matches(in: string, options: [], range: tag.range)
            for quote in quotes {
                addAttribute(.foregroundColor, value: quotedColor, range: quote.range)
            }
        }

        let comments = RegExes.comments.matches(in: string, options: [], range: fullStringRange)
        for comment in comments {
            addAttribute(.foregroundColor, value: commentColor, range: comment.range)
        }

        edited(.editedAttributes, range: fullStringRange, changeInLength: 0)
    }
}


// MARK: - Constants
//
extension HTMLStorage {

    /// Regular Expressions used to match HTML
    ///
    private struct RegExes {
        static let comments = try! NSRegularExpression(pattern: "<!--[^>]+-->", options: .caseInsensitive)
        static let html = try! NSRegularExpression(pattern: "<[^>]+>", options: .caseInsensitive)
        static let quotes = try! NSRegularExpression(pattern: "\".*?\"", options: .caseInsensitive)
    }


    /// Default Styles
    ///
    public struct Styles {
        static let defaultTextColor = UIColor.black
        static let defaultCommentColor = UIColor.lightGray
        static let defaultTagColor = UIColor(red: 0x00/255.0, green: 0x75/255.0, blue: 0xB6/255.0, alpha: 0xFF/255.0)
        static let defaultQuotedColor = UIColor(red: 0x6E/255.0, green: 0x96/255.0, blue: 0xB1/255.0, alpha: 0xFF/255.0)
    }
}
