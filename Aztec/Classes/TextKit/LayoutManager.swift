import Foundation
import UIKit
import QuartzCore


// MARK: - Aztec Layout Manager
//
class LayoutManager: NSLayoutManager {

    /// Blockquote's Left Border Color
    ///
    var blockquoteBorderColor = UIColor(red: 0.52, green: 0.65, blue: 0.73, alpha: 1.0)

    /// Blockquote's Background Color
    ///
    var blockquoteBackgroundColor = UIColor(red: 0.91, green: 0.94, blue: 0.95, alpha: 1.0)


    /// HTML Pre Background Color
    ///
    var preBackgroundColor = UIColor(red: 243.0/255.0, green: 246.0/255.0, blue: 248.0/255.0, alpha: 1.0)

    /// Draws the background, associated to a given Text Range
    ///
    override func drawBackground(forGlyphRange glyphsToShow: NSRange, at origin: CGPoint) {
        super.drawBackground(forGlyphRange: glyphsToShow, at: origin)

        drawBlockquotes(forGlyphRange: glyphsToShow, at: origin)
        drawHTMLPre(forGlyphRange: glyphsToShow, at: origin)
        drawLists(forGlyphRange: glyphsToShow, at: origin)
    }
}


// MARK: - Blockquote Helpers
//
private extension LayoutManager {

    /// Draws a Blockquote associated to a Range + Graphics Origin.
    ///
    func drawBlockquotes(forGlyphRange glyphsToShow: NSRange, at origin: CGPoint) {
        guard let textStorage = textStorage else {
            return
        }

        guard let context = UIGraphicsGetCurrentContext() else {
            preconditionFailure("When drawBackgroundForGlyphRange is called, the graphics context is supposed to be set by UIKit")
        }

        let characterRange = self.characterRange(forGlyphRange: glyphsToShow, actualGlyphRange: nil)
        //draw blockquotes
        textStorage.enumerateAttribute(NSParagraphStyleAttributeName, in: characterRange, options: []){ (object, range, stop) in
            guard let paragraphStyle = object as? ParagraphStyle, !paragraphStyle.blockquotes.isEmpty else {
                return
            }
            let blockquoteIndent = paragraphStyle.blockquoteIndent

            let blockquoteGlyphRange = glyphRange(forCharacterRange: range, actualCharacterRange: nil)

            enumerateLineFragments(forGlyphRange: blockquoteGlyphRange) { (rect, usedRect, textContainer, glyphRange, stop) in
                let paddingWidth = blockquoteIndent + (blockquoteIndent == 0 ? 0 : (Metrics.listTextIndentation / 2))
                var paddingHeight: CGFloat = blockquoteIndent == 0 ? 0 : (Metrics.paragraphSpacing / 2)
                //cheking if we this a middle line inside a blockquote paragraph
                let lineRange = self.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)
                let lineCharacters = textStorage.attributedSubstring(from: lineRange).string
                if !lineCharacters.isEndOfLine(before: lineCharacters.endIndex) {
                    paddingHeight = 0
                }
                let lineRect = rect.offsetBy(dx: origin.x , dy: origin.y)
                let finalRect = CGRect(x: lineRect.origin.x + paddingWidth, y: lineRect.origin.y, width: lineRect.size.width - paddingWidth, height: lineRect.size.height - (paddingHeight*2))
                self.drawBlockquote(in: finalRect.integral, with: context)
            }
        }

    }

    /// Draws a single Blockquote Line Fragment, in the specified Rectangle, using a given Graphics Context.
    ///
    private func drawBlockquote(in rect: CGRect, with context: CGContext) {
        blockquoteBackgroundColor.setFill()
        context.fill(rect)

        let borderRect = CGRect(origin: rect.origin, size: CGSize(width: 2, height: rect.height))
        blockquoteBorderColor.setFill()
        context.fill(borderRect)
    }
}

// MARK: - PreFormatted Helpers
//
private extension LayoutManager {

    /// Draws a HTML Pre associated to a Range + Graphics Origin.
    ///
    func drawHTMLPre(forGlyphRange glyphsToShow: NSRange, at origin: CGPoint) {
        guard let textStorage = textStorage else {
            return
        }

        guard let context = UIGraphicsGetCurrentContext() else {
            preconditionFailure("When drawBackgroundForGlyphRange is called, the graphics context is supposed to be set by UIKit")
        }

        let characterRange = self.characterRange(forGlyphRange: glyphsToShow, actualGlyphRange: nil)
        //draw html pre paragraphs
        textStorage.enumerateAttribute(NSParagraphStyleAttributeName, in: characterRange, options: []){ (object, range, stop) in
            guard let paragraphStyle = object as? ParagraphStyle, paragraphStyle.htmlPre != nil else {
                return
            }

            let preGlyphRange = glyphRange(forCharacterRange: range, actualCharacterRange: nil)

            enumerateLineFragments(forGlyphRange: preGlyphRange) { (rect, usedRect, textContainer, glyphRange, stop) in
                let lineRect = rect.offsetBy(dx: origin.x, dy: origin.y)
                self.drawHTMLPre(in: lineRect.integral, with: context)
            }
        }

    }

    /// Draws a single HTML Pre Line Fragment, in the specified Rectangle, using a given Graphics Context.
    ///
    private func drawHTMLPre(in rect: CGRect, with context: CGContext) {
        preBackgroundColor.setFill()
        context.fill(rect)
    }
}

// MARK: - Lists Helpers
//
private extension LayoutManager {

    /// Draws a TextList associated to a Range + Graphics Origin.
    ///
    func drawLists(forGlyphRange glyphsToShow: NSRange, at origin: CGPoint) {
        guard let textStorage = textStorage else {
            return
        }

        let characterRange = self.characterRange(forGlyphRange: glyphsToShow, actualGlyphRange: nil)

        textStorage.enumerateParagraphRanges(spanning: characterRange) { (range, enclosingRange) in

            guard textStorage.string.isStartOfNewLine(atUTF16Offset: enclosingRange.location),
                let paragraphStyle = textStorage.attribute(NSParagraphStyleAttributeName, at: enclosingRange.location, effectiveRange: nil) as? ParagraphStyle,
                let list = paragraphStyle.lists.last else {
                    return
            }

            let glyphRange = self.glyphRange(forCharacterRange: enclosingRange, actualCharacterRange: nil)

            // Since only the first line in a paragraph can have a bullet, we only need the first line fragment.
            //
            let lineFragmentRect = self.lineFragmentRect(forGlyphAt: glyphRange.location, effectiveRange: nil)
            let lineFragmentRectWithOffset = lineFragmentRect.offsetBy(dx: origin.x, dy: origin.y)

            let markerNumber = textStorage.itemNumber(in: list, at: enclosingRange.location)

            self.drawItem(
                number: markerNumber,
                in: lineFragmentRectWithOffset,
                from: list,
                using: paragraphStyle,
                at: enclosingRange.location)
        }
    }


    /// Draws the specified List Item Number, at a given location.
    ///
    /// - Parameters:
    ///     - number: Marker Number of the item to be drawn
    ///     - rect: Visible Rect in which the Marker should be rendered
    ///     - list: Associated TextList
    ///     - style: ParagraphStyle associated to the list
    ///     - location: Text Location that should get the marker rendered.
    ///
    private func drawItem(number: Int, in rect: CGRect, from list: TextList, using style: ParagraphStyle, at location: Int) {
        guard let textStorage = textStorage else {
            return
        }

        let paragraphAttributes = textStorage.attributes(at: location, effectiveRange: nil)
        let markerAttributes = markerAttributesBasedOnParagraph(attributes: paragraphAttributes)

        let markerPlain = list.style.markerText(forItemNumber: number)
        let markerText = NSAttributedString(string: markerPlain, attributes: markerAttributes)

        var yOffset = -style.paragraphSpacingBefore

        if let font = markerAttributes[NSFontAttributeName] as? UIFont {
            yOffset += (rect.height - font.lineHeight)
        }

        let markerRect = rect.offsetBy(dx: 0, dy: yOffset)
        markerText.draw(in: markerRect)
    }


    /// Returns the Marker Text Attributes, based on a collection that defines Regular Text Attributes.
    ///
    private func markerAttributesBasedOnParagraph(attributes: [String: Any]) -> [String: Any] {
        var resultAttributes = attributes
        var indent: CGFloat = 0
        if let style = attributes[NSParagraphStyleAttributeName] as? ParagraphStyle {
            indent = style.listIndent + Metrics.listTextIndentation
        }

        resultAttributes[NSParagraphStyleAttributeName] = markerParagraphStyle(indent: indent)
        resultAttributes.removeValue(forKey: NSUnderlineStyleAttributeName)
        resultAttributes.removeValue(forKey: NSStrikethroughStyleAttributeName)
        resultAttributes.removeValue(forKey: NSLinkAttributeName)

        if let font = resultAttributes[NSFontAttributeName] as? UIFont {
            resultAttributes[NSFontAttributeName] = fixFontForMarkerAttributes(font: font)
        }

        return resultAttributes
    }


    /// Returns the Marker Paratraph Attributes
    ///
    private func markerParagraphStyle(indent: CGFloat) -> NSParagraphStyle {
        let tabStop = NSTextTab(textAlignment: .right, location: indent, options: [:])
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.tabStops = [tabStop]

        return paragraphStyle
    }


    /// Fixes a UIFont Instance for List Marker Usage:
    ///
    /// - Emoji Font is replaced by the System's font, of matching size
    /// - Bold and Italic styling is neutralized
    ///
    private func fixFontForMarkerAttributes(font: UIFont) -> UIFont {
        guard !font.isAppleEmojiFont else {
            return UIFont.systemFont(ofSize: font.pointSize)
        }

        var traits = font.fontDescriptor.symbolicTraits
        traits.remove(.traitBold)
        traits.remove(.traitItalic)

        let descriptor = font.fontDescriptor.withSymbolicTraits(traits)
        return UIFont(descriptor: descriptor!, size: font.pointSize)
    }
}
