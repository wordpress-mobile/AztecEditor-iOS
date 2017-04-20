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


    /// Draws the background, associated to a given Text Range
    ///
    override func drawBackground(forGlyphRange glyphsToShow: NSRange, at origin: CGPoint) {
        super.drawBackground(forGlyphRange: glyphsToShow, at: origin)

        drawBlockquotes(forGlyphRange: glyphsToShow, at: origin)
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
            guard let paragraphStyle = object as? ParagraphStyle, paragraphStyle.blockquote != nil else {
                return
            }

            let blockquoteGlyphRange = glyphRange(forCharacterRange: range, actualCharacterRange: nil)

            enumerateLineFragments(forGlyphRange: blockquoteGlyphRange) { (rect, usedRect, textContainer, glyphRange, stop) in
                let lineRect = rect.offsetBy(dx: origin.x, dy: origin.y)
                self.drawBlockquote(in: lineRect, with: context)
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
        textStorage.enumerateAttribute(NSParagraphStyleAttributeName, in: characterRange, options: []) { (object, range, stop) in
            guard let paragraphStyle = object as? ParagraphStyle, let list = paragraphStyle.textList else {
                return
            }

            let listGlyphRange = glyphRange(forCharacterRange:range, actualCharacterRange: nil)

            // Draw Paragraph Markers
            enumerateLineFragments(forGlyphRange: listGlyphRange) { (rect, usedRect, textContainer, glyphRange, stop) in
                let location = self.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil).location
                guard textStorage.isStartOfNewLine(atLocation: location) else {
                    return
                }

                let markerNumber = textStorage.itemNumber(in: list, at: location)
                let lineRect = rect.offsetBy(dx: origin.x, dy: origin.y)

                self.drawItem(number: markerNumber, in: lineRect, from: list, using: paragraphStyle, at: location)
            }
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

        let markerRect = rect.offsetBy(dx: style.headIndent - Metrics.listTextIndentation, dy: style.paragraphSpacingBefore)

        markerText.draw(in: markerRect)
    }


    /// Returns the Marker Text Attributes, based on a collection that defines Regular Text Attributes.
    ///
    private func markerAttributesBasedOnParagraph(attributes: [String: Any]) -> [String: Any] {
        var resultAttributes = attributes
        resultAttributes[NSParagraphStyleAttributeName] = markerParagraphStyle()
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


    /// Returns the Marker Paratraph Attributes
    ///
    private func markerParagraphStyle() -> NSParagraphStyle {
        let tabStop = NSTextTab(textAlignment: .right, location: Metrics.listBulletIndentation, options: [:])
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.tabStops = [tabStop]

        return paragraphStyle
    }
}
