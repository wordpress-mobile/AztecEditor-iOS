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

    /// Closure that is expected to return the TypingAttributes associated to the Extra Line Fragment
    ///
    var extraLineFragmentTypingAttributes: (() -> [NSAttributedString.Key: Any])?

    /// Blockquote's Left Border width
    ///
    var blockquoteBorderWidth: CGFloat = 2


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

        // Draw: Blockquotes
        textStorage.enumerateAttribute(.paragraphStyle, in: characterRange, options: []) { (object, range, stop) in
            guard let paragraphStyle = object as? ParagraphStyle, !paragraphStyle.blockquotes.isEmpty else {
                return
            }

            let blockquoteIndent = paragraphStyle.blockquoteIndent
            let blockquoteGlyphRange = glyphRange(forCharacterRange: range, actualCharacterRange: nil)

            enumerateLineFragments(forGlyphRange: blockquoteGlyphRange) { (rect, usedRect, textContainer, glyphRange, stop) in
                let lineRange = self.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)
                let lineCharacters = textStorage.attributedSubstring(from: lineRange).string
                let lineEndsParagraph = lineCharacters.isEndOfParagraph(before: lineCharacters.endIndex)
                let blockquoteRect = self.blockquoteRect(origin: origin, lineRect: rect, blockquoteIndent: blockquoteIndent, lineEndsParagraph: lineEndsParagraph)

                self.drawBlockquote(in: blockquoteRect.integral, with: context)
            }
        }

        // Draw: Extra Line Fragment
        guard extraLineFragmentRect.height != 0,
            let typingAttributes = extraLineFragmentTypingAttributes?() else {
                return
        }

        guard let paragraphStyle = typingAttributes[.paragraphStyle] as? ParagraphStyle,
            !paragraphStyle.blockquotes.isEmpty else {
                return
        }

        let extraIndent = paragraphStyle.blockquoteIndent
        let extraRect = blockquoteRect(origin: origin, lineRect: extraLineFragmentRect, blockquoteIndent: extraIndent, lineEndsParagraph: false)

        drawBlockquote(in: extraRect.integral, with: context)
    }


    /// Returns the Rect in which the Blockquote should be rendered.
    ///
    /// - Parameters:
    ///     - origin: Origin of coordinates
    ///     - lineRect: Line Fragment's Rect
    ///     - blockquoteIndent: Blockquote Indentation Level for the current lineFragment
    ///     - lineEndsParagraph: Indicates if the current blockquote line is the end of a Paragraph
    ///
    /// - Returns: Rect in which we should render the blockquote.
    ///
    private func blockquoteRect(origin: CGPoint, lineRect: CGRect, blockquoteIndent: CGFloat, lineEndsParagraph: Bool) -> CGRect {
        var blockquoteRect = lineRect.offsetBy(dx: origin.x, dy: origin.y)
        
        guard blockquoteIndent != 0 else {
            return blockquoteRect
        }

        let paddingWidth = Metrics.listTextIndentation * 0.5 + blockquoteIndent
        blockquoteRect.origin.x += paddingWidth
        blockquoteRect.size.width -= paddingWidth

        // Ref. Issue #645: Cheking if we this a middle line inside a blockquote paragraph
        if lineEndsParagraph {
            blockquoteRect.size.height -= Metrics.paragraphSpacing * 0.5
        }

        return blockquoteRect
    }

    /// Draws a single Blockquote Line Fragment, in the specified Rectangle, using a given Graphics Context.
    ///
    private func drawBlockquote(in rect: CGRect, with context: CGContext) {
        blockquoteBackgroundColor.setFill()
        context.fill(rect)

        let borderRect = CGRect(origin: rect.origin, size: CGSize(width: blockquoteBorderWidth, height: rect.height))
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
        textStorage.enumerateAttribute(.paragraphStyle, in: characterRange, options: []){ (object, range, stop) in
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
                let paragraphStyle = textStorage.attribute(.paragraphStyle, at: enclosingRange.location, effectiveRange: nil) as? ParagraphStyle,
                let list = paragraphStyle.lists.last
            else {
                return
            }

            let glyphRange = self.glyphRange(forCharacterRange: enclosingRange, actualCharacterRange: nil)
            let markerRect = rectForItem(range: glyphRange, origin: origin, paragraphStyle: paragraphStyle)
            let markerNumber = textStorage.itemNumber(in: list, at: enclosingRange.location)

            drawItem(number: markerNumber, in: markerRect, from: list, using: paragraphStyle, at: enclosingRange.location)
        }
    }


    /// Returns the Rect for the MarkerItem at the specified Range + Origin, within a given ParagraphStyle.
    ///
    /// - Parameters:
    ///     - range: List Item's Range
    ///     - origin: List Origin
    ///     - paragraphStyle: Container Style
    ///
    /// - Returns: CGRect in which we should render the MarkerItem.
    ///
    private func rectForItem(range: NSRange, origin: CGPoint, paragraphStyle: ParagraphStyle) -> CGRect {
        var paddingY = CGFloat(0)
        var effectiveLineRange = NSRange.zero

        // Since only the first line in a paragraph can have a bullet, we only need the first line fragment.
        let lineFragmentRect = self.lineFragmentRect(forGlyphAt: range.location, effectiveRange: &effectiveLineRange)

        // Whenever we're rendering an Item with multiple lines, within a Blockquote, we need to account for the
        // paragraph spacing. Otherwise the Marker will show up slightly off.
        //
        // Ref. #645
        //
        if effectiveLineRange.length < range.length && paragraphStyle.blockquotes.isEmpty == false {
            paddingY = Metrics.paragraphSpacing
        }

        return lineFragmentRect.offsetBy(dx: origin.x, dy: origin.y + paddingY)
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

        var yOffset = CGFloat(0)

        if location > 0 {
            yOffset += style.paragraphSpacingBefore
        }

        let markerRect = rect.offsetBy(dx: 0, dy: yOffset)
        markerText.draw(in: markerRect)
    }


    /// Returns the Marker Text Attributes, based on a collection that defines Regular Text Attributes.
    ///
    private func markerAttributesBasedOnParagraph(attributes: [NSAttributedString.Key: Any]) -> [NSAttributedString.Key: Any] {
        var resultAttributes = attributes
        var indent: CGFloat = 0
        if let style = attributes[.paragraphStyle] as? ParagraphStyle {
            indent = style.listIndent + Metrics.listTextIndentation
        }

        resultAttributes[.paragraphStyle] = markerParagraphStyle(indent: indent)
        resultAttributes.removeValue(forKey: .underlineStyle)
        resultAttributes.removeValue(forKey: .strikethroughStyle)
        resultAttributes.removeValue(forKey: .link)

        if let font = resultAttributes[.font] as? UIFont {
            resultAttributes[.font] = fixFontForMarkerAttributes(font: font)
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

        if let descriptor = font.fontDescriptor.withSymbolicTraits(traits) {
            return UIFont(descriptor: descriptor, size: font.pointSize)
        } else {
            // Don't touch the font if we cannot remove the symbolic traits.
            return font
        }
    }
}
