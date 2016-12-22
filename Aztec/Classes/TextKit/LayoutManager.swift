import Foundation
import UIKit
import QuartzCore

class LayoutManager: NSLayoutManager {

    var blockquoteBorderColor: UIColor = UIColor(red: 0.52, green: 0.65, blue: 0.73, alpha: 1.0)
    var blockquoteBackgroundColor = UIColor(red: 0.91, green: 0.94, blue: 0.95, alpha: 1.0)

    override func drawBackground(forGlyphRange glyphsToShow: NSRange, at origin: CGPoint) {
        super.drawBackground(forGlyphRange: glyphsToShow, at: origin)

        drawBlockquotes(forGlyphRange: glyphsToShow, at: origin)
        drawLists(forGlyphRange: glyphsToShow, at: origin)
    }

    private func drawBlockquotes(forGlyphRange glyphsToShow: NSRange, at origin: CGPoint) {
        guard let textStorage = textStorage else {
            return
        }

        guard let context = UIGraphicsGetCurrentContext() else {
            preconditionFailure("When drawBackgroundForGlyphRange is called, the graphics context is supposed to be set by UIKit")
        }

        let characterRange = self.characterRange(forGlyphRange: glyphsToShow, actualGlyphRange: nil)
        //draw blockquotes
        textStorage.enumerateAttribute(NSParagraphStyleAttributeName, in: characterRange, options: []){ (object, range, stop) in
            guard let paragraphStyle = object as? ParagraphStyle, paragraphStyle.blockquote != nil else {
                return
            }

            let blockquoteGlyphRange = glyphRange(forCharacterRange: range, actualCharacterRange: nil)

            enumerateLineFragments(forGlyphRange: blockquoteGlyphRange) { (rect, usedRect, textContainer, glyphRange, stop) in
                let lineRect = rect.offsetBy(dx: origin.x, dy: origin.y)
                self.drawBlockquote(in: lineRect, with: context)
            }

            if range.endLocation == textStorage.rangeOfEntireString.endLocation {
                let extraLineRect = extraLineFragmentRect.offsetBy(dx: origin.x, dy: origin.y)
                drawBlockquote(in: extraLineRect, with: context)
            }
        }

    }

    private func drawBlockquote(in rect: CGRect, with context: CGContext) {
        blockquoteBackgroundColor.setFill()
        context.fill(rect)

        let borderRect = CGRect(origin: rect.origin, size: CGSize(width: 2, height: rect.height))
        blockquoteBorderColor.setFill()
        context.fill(borderRect)
    }

    private func drawLists(forGlyphRange glyphsToShow: NSRange, at origin: CGPoint) {
        guard let textStorage = textStorage else {
            return
        }

        let characterRange = self.characterRange(forGlyphRange: glyphsToShow, actualGlyphRange: nil)
        // draw list markers
        textStorage.enumerateAttribute(NSParagraphStyleAttributeName, in: characterRange, options: []){ (object, range, stop) in
            guard let paragraphStyle = object as? ParagraphStyle,
                  paragraphStyle.textList != nil
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
                    let markerRect = lineRect.offsetBy(dx: paragraphStyle.headIndent - Metrics.defaultIndentation, dy: paragraphStyle.paragraphSpacingBefore)
                    let markerAttributes = self.markerAttributesBasedOnParagraph(attributes: attributes)
                    let markerText = NSAttributedString(string:textList.style.markerText(forItemNumber: number), attributes:markerAttributes)
                    markerText.draw(in: markerRect)
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
