import Foundation
import UIKit
import QuartzCore

class LayoutManager: NSLayoutManager {

    override func drawBackground(forGlyphRange glyphsToShow: NSRange, at origin: CGPoint) {
        super.drawBackground(forGlyphRange: glyphsToShow, at: origin)
        guard let textStorage = textStorage else {
            return
        }

        guard let context = UIGraphicsGetCurrentContext() else {
            preconditionFailure("When drawBackgroundForGlyphRange is called, the graphics context is supposed to be set by UIKit")
        }

        let characterRange = self.characterRange(forGlyphRange: glyphsToShow, actualGlyphRange: nil)
        textStorage.enumerateAttribute(Blockquote.attributeName, in: characterRange, options: []){ (object, range, stop) in
            guard object is Blockquote else {
                return
            }

            let borderColor = UIColor(red: 0.5294117647, green: 0.650980392156863, blue: 0.737254902, alpha: 1.0)
            let backgroundColor = UIColor(red: 0.91, green: 0.94, blue: 0.95, alpha: 1.0)
            let blockquoteGlyphRange = glyphRange(forCharacterRange: range, actualCharacterRange: nil)

            enumerateLineFragments(forGlyphRange: blockquoteGlyphRange) { (rect, usedRect, textContainer, glyphRange, stop) in
                let lineRect = rect.offsetBy(dx: origin.x, dy: origin.y)
                backgroundColor.setFill()
                context.fill(lineRect)
                let borderRect = CGRect(origin: lineRect.origin, size: CGSize(width: 2, height: lineRect.height))
                borderColor.setFill()
                context.fill(borderRect)
            }
        }

        // draw list markers
        textStorage.enumerateAttribute(TextListItem.attributeName, in: characterRange, options: []){ (object, range, stop) in
            guard let textListItem = object as? TextListItem,
                  let textList = textStorage.attribute(TextList.attributeName, at: range.location, effectiveRange: nil) as? TextList
                else {
                return
            }

            let listGlyphRange = glyphRange(forCharacterRange:range, actualCharacterRange: nil)

            enumerateLineFragments(forGlyphRange:listGlyphRange) { (rect, usedRect, textContainer, glyphRange, stop) in
                let lineRect = rect.offsetBy(dx: origin.x, dy: origin.y)
                let lineRange = self.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)
                let isStartOfLine = textStorage.isStartOfNewLine(atLocation: lineRange.location)
                var attributes = textStorage.attributes(at: lineRange.location, effectiveRange: nil)
                attributes[NSParagraphStyleAttributeName] = NSParagraphStyle.Aztec.defaultParagraphStyle
                if isStartOfLine {
                    let markerText = NSAttributedString(string:textList.style.markerText(forItemNumber: textListItem.number), attributes:attributes)
                    markerText.draw(in: lineRect)
                }
            }
        }
    }
}
