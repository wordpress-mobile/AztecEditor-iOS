import Foundation
import UIKit

public extension NSMutableAttributedString {

    /// Replace all instances of the .font attribute that belong to the same family for the new font, trying to keep the same symbolic traits
    /// - Parameter font: the original font to be replaced
    /// - Parameter newFont: the new font to use.
    func replace(font: UIFont, with newFont: UIFont) {
        let fullRange = NSRange(location: 0, length: length)

        beginEditing()
        enumerateAttributes(in: fullRange, options: []) { (attributes, subrange, stop) in
            guard let currentFont = attributes[.font] as? UIFont, currentFont.familyName == font.familyName else {
                return
            }
            var replacementFont = newFont
            if let fontDescriptor = newFont.fontDescriptor.withSymbolicTraits(currentFont.fontDescriptor.symbolicTraits) {
                replacementFont = UIFont(descriptor: fontDescriptor, size: currentFont.pointSize)
            }
            addAttribute(.font, value: replacementFont, range: subrange)
        }
        endEditing()
    }
}
