import Foundation
import UIKit


//
//
public extension NSTextStorage {

    ///
    ///
    private struct RegExes {

        ///
        ///
        static let html = try! NSRegularExpression(pattern: "<[^>]+>", options: .caseInsensitive)

        ///
        ///
        static let quotes = try! NSRegularExpression(pattern: "\".*?\"", options: .caseInsensitive)
    }


    ///
    ///
    struct Styles {
        static let defaultTagColor = UIColor(colorLiteralRed: 0x00/255.0, green: 0x75/255.0, blue: 0xB6/255.0, alpha: 0xFF/255.0)
        static let defaultQuotedColor = UIColor(colorLiteralRed: 0x6E/255.0, green: 0x96/255.0, blue: 0xB1/255.0, alpha: 0xFF/255.0)
    }


    ///
    ///
    func colorizeHTML(font: UIFont, tagColor: UIColor = Styles.defaultTagColor, quoteColor: UIColor = Styles.defaultQuotedColor) {
        beginEditing()

        let fullStringRange = rangeOfEntireString

        removeAttribute(NSForegroundColorAttributeName, range: fullStringRange)
        addAttribute(NSFontAttributeName, value: font, range: fullStringRange)

        let tags = RegExes.html.matches(in: string, options: [], range: fullStringRange)
        for tag in tags {
            addAttribute(NSForegroundColorAttributeName, value: tagColor, range: tag.range)

            let quotes = RegExes.quotes.matches(in: string, options: [], range: tag.range)
            for quote in quotes {
                addAttribute(NSForegroundColorAttributeName, value: quoteColor, range: quote.range)
            }
        }

        endEditing()
    }
}
