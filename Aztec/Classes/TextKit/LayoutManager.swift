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

        //draw blockquotes
        textStorage.enumerateAttribute(NSParagraphStyleAttributeName, in: characterRange, options: []){ (object, range, stop) in
            guard let paragraphStyle = object as? ParagraphStyle,
                let _ = paragraphStyle.blockquote
                else {
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
        textStorage.enumerateAttribute(NSParagraphStyleAttributeName, in: characterRange, options: []){ (object, range, stop) in
            guard let paragraphStyle = object as? ParagraphStyle,
                  let _ = paragraphStyle.textList
                else {
                return
            }

            let listGlyphRange = glyphRange(forCharacterRange:range, actualCharacterRange: nil)

            enumerateLineFragments(forGlyphRange:listGlyphRange) { (rect, usedRect, textContainer, glyphRange, stop) in
                let lineRect = rect.offsetBy(dx: origin.x, dy: origin.y)
                let lineRange = self.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)
                guard let textList = textStorage.textListAttribute(atIndex: lineRange.location)
                    else {
                        return
                }
                let number = textStorage.itemNumber(in: textList, at: lineRange.location)
                let isStartOfLine = textStorage.isStartOfNewLine(atLocation: lineRange.location)
                let attributes = textStorage.attributes(at: lineRange.location, effectiveRange: nil)
                if isStartOfLine {
                    let markerAttributes = self.markerAttributesBasedOnParagraph(attributes: attributes)
                    let markerText = NSAttributedString(string:textList.style.markerText(forItemNumber: number), attributes:markerAttributes)
                    markerText.draw(in: lineRect)
                }
            }
        }
    }

    private func markerAttributesBasedOnParagraph(attributes: [String: Any]) -> [String: Any] {
        var resultAttributes = attributes
        resultAttributes[NSParagraphStyleAttributeName] = ParagraphStyle.default
        resultAttributes.removeValue(forKey: NSUnderlineStyleAttributeName)
        resultAttributes.removeValue(forKey: NSStrikethroughStyleAttributeName)
        resultAttributes.removeValue(forKey: NSLinkAttributeName)
        if let font = resultAttributes[NSFontAttributeName] as? UIFont {
            var traits = font.fontDescriptor.symbolicTraits
            traits.remove(.traitBold)
            traits.remove(.traitItalic)
            let descriptor = font.fontDescriptor.withSymbolicTraits(traits)
            let newFont = UIFont(descriptor: descriptor!, size: font.pointSize)
            resultAttributes[NSFontAttributeName] = newFont
        }
        return resultAttributes
    }
}
