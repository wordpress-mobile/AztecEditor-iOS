import Foundation
import UIKit


// MARK: - NSTextStorage Implementation: Automatically colorizes all of the present HTML Tags.
//
open class HTMLStorage: NSTextStorage {

    /// Internal Storage
    ///
    private var textStore = NSMutableAttributedString(string: "", attributes: nil)

    /// Document's Font
    ///
    open var font: UIFont

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

    public init(defaultFont: UIFont) {
        font = defaultFont
        super.init()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError()
    }


    // MARK: - Overriden Methods

    override open var string: String {
        return textStore.string
    }

    override open func attributes(at location: Int, effectiveRange range: NSRangePointer?) -> [String : Any] {
        guard textStore.length != 0 else {
            return [:]
        }

        return textStore.attributes(at: location, effectiveRange: range)
    }

    override open func setAttributes(_ attrs: [String : Any]?, range: NSRange) {
        beginEditing()

        textStore.setAttributes(attrs, range: range)
        edited(.editedAttributes, range: range, changeInLength: 0)

        endEditing()
    }

    override open func addAttribute(_ name: String, value: Any, range: NSRange) {
        textStore.addAttribute(name, value: value, range: range)
    }

    override open func removeAttribute(_ name: String, range: NSRange) {
        textStore.removeAttribute(name, range: range)
    }

    override open func replaceCharacters(in range: NSRange, with str: String) {
        beginEditing()

        textStore.replaceCharacters(in: range, with: str)
        edited([.editedAttributes, .editedCharacters], range: range, changeInLength: string.characters.count - range.length)

        endEditing()
    }

    override open func replaceCharacters(in range: NSRange, with attrString: NSAttributedString) {
        beginEditing()

        textStore.replaceCharacters(in: range, with: attrString)
        edited([.editedAttributes, .editedCharacters], range: range, changeInLength: attrString.length - range.length)
        
        endEditing()
    }

    override open func processEditing() {
        colorizeHTML()
        super.processEditing()
    }
}


// MARK: - Private Helpers
//
private extension HTMLStorage {

    /// Colorizes all of the HTML Tags contained within this Storage
    ///
    func colorizeHTML() {
        let fullStringRange = rangeOfEntireString

        removeAttribute(NSForegroundColorAttributeName, range: fullStringRange)
        addAttribute(NSFontAttributeName, value: font, range: fullStringRange)

        let tags = RegExes.html.matches(in: string, options: [], range: fullStringRange)
        for tag in tags {
            addAttribute(NSForegroundColorAttributeName, value: tagColor, range: tag.range)

            let quotes = RegExes.quotes.matches(in: string, options: [], range: tag.range)
            for quote in quotes {
                addAttribute(NSForegroundColorAttributeName, value: quotedColor, range: quote.range)
            }
        }

        let comments = RegExes.comments.matches(in: string, options: [], range: fullStringRange)
        for comment in comments {
            addAttribute(NSForegroundColorAttributeName, value: commentColor, range: comment.range)
        }
    }
}


// MARK: - Constants
//
private extension HTMLStorage {

    /// Regular Expressions used to match HTML
    ///
    struct RegExes {
        static let comments = try! NSRegularExpression(pattern: "<!--[^>]+-->", options: .caseInsensitive)
        static let html = try! NSRegularExpression(pattern: "<[^>]+>", options: .caseInsensitive)
        static let quotes = try! NSRegularExpression(pattern: "\".*?\"", options: .caseInsensitive)
    }


    /// Default Styles
    ///
    struct Styles {
        static let defaultCommentColor = UIColor.lightGray
        static let defaultTagColor = UIColor(colorLiteralRed: 0x00/255.0, green: 0x75/255.0, blue: 0xB6/255.0, alpha: 0xFF/255.0)
        static let defaultQuotedColor = UIColor(colorLiteralRed: 0x6E/255.0, green: 0x96/255.0, blue: 0xB1/255.0, alpha: 0xFF/255.0)
    }
}
