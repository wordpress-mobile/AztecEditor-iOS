import Foundation
import UIKit
import QuartzCore

class LayoutManager: NSLayoutManager {

    override func drawBackgroundForGlyphRange(glyphsToShow: NSRange, atPoint origin: CGPoint) {
        super.drawBackgroundForGlyphRange(glyphsToShow, atPoint: origin)
        guard let textStorage = textStorage else {
            return
        }

        guard let context = UIGraphicsGetCurrentContext() else {
            preconditionFailure("When drawBackgroundForGlyphRange is called, the graphics context is supposed to be set by UIKit")
        }

        let characterRange = characterRangeForGlyphRange(glyphsToShow, actualGlyphRange: nil)
        textStorage.enumerateAttribute(Blockquote.attributeName, inRange: characterRange, options: []){ (object, range, stop) in
            guard object is Blockquote else {
                return
            }

            let borderColor = UIColor(red: 0.5294117647, green: 0.650980392156863, blue: 0.737254902, alpha: 1.0)
            let backgroundColor = UIColor(red: 0.91, green: 0.94, blue: 0.95, alpha: 1.0)
            let blockquoteGlyphRange = glyphRangeForCharacterRange(range, actualCharacterRange: nil)

            enumerateLineFragmentsForGlyphRange(blockquoteGlyphRange) { (rect, usedRect, textContainer, glyphRange, stop) in
                let lineRect = rect.offsetBy(dx: origin.x, dy: origin.y)
                backgroundColor.setFill()
                CGContextFillRect(context, lineRect)
                let borderRect = CGRect(origin: lineRect.origin, size: CGSize(width: 2, height: lineRect.height))
                borderColor.setFill()
                CGContextFillRect(context, borderRect)
            }
        }

        // draw list markers
        textStorage.enumerateAttribute(TextListItem.attributeName, inRange: characterRange, options: []){ (object, range, stop) in
            guard let textListItem = object as? TextListItem,
                  let textList = textStorage.attribute(TextList.attributeName, atIndex: range.location, effectiveRange: nil) as? TextList
                else {
                return
            }

            let listGlyphRange = glyphRangeForCharacterRange(range, actualCharacterRange: nil)

            enumerateLineFragmentsForGlyphRange(listGlyphRange) { (rect, usedRect, textContainer, glyphRange, stop) in
                let lineRect = rect.offsetBy(dx: origin.x, dy: origin.y)
                let lineRange = self.characterRangeForGlyphRange(glyphRange, actualGlyphRange: nil)
                let isStartOfLine = textStorage.isStartOfNewLine(atLocation: lineRange.location)
                var attributes = textStorage.attributesAtIndex(lineRange.location, effectiveRange: nil)
                attributes[NSParagraphStyleAttributeName] = NSParagraphStyle.Aztec.defaultParagraphStyle
                if isStartOfLine {
                    let markerText = NSAttributedString(string:textList.style.markerText(forItemNumber: textListItem.number), attributes:attributes)
                    markerText.drawInRect(lineRect)
                }
            }
        }
    }
}
