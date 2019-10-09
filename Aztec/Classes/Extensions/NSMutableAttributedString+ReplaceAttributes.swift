import Foundation
import UIKit

public extension NSMutableAttributedString {

    func replace(font: UIFont, with newFont: UIFont) {
        let fullRange = NSRange(location: 0, length: self.length)

        self.beginEditing()
        self.enumerateAttributes(in: fullRange, options: []) { (attributes, subrange, stop) in
            if let currentFont = attributes[.font] as? UIFont, currentFont.familyName == font.familyName {
                var replacementFont = newFont
                if let fontDescriptor = newFont.fontDescriptor.withSymbolicTraits(currentFont.fontDescriptor.symbolicTraits) {
                    replacementFont = UIFont(descriptor: fontDescriptor, size: currentFont.pointSize)
                }
                self.addAttribute(.font, value: replacementFont, range: subrange)
            }
        }
        self.endEditing()
    }
}
