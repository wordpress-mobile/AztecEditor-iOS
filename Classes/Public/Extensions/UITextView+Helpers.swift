import UIKit

/// A helper extension for UITextView.
///
extension UITextView
{

    /// A convenience metod for getting the CGRect of the currentl text selection.
    ///
    /// - Returns: The CGRect of the current text selection.
    ///
    public func rectForCurrentSelection() -> CGRect {
        return layoutManager.boundingRectForGlyphRange(selectedRange, inTextContainer: textContainer)
    }


    /// Converts the current Attributed Text into a raw HTML String
    ///
    /// - Returns: The HTML version of the current Attributed String.
    ///
    public func exportHTML() -> String {
        let converter = Libxml2.Out.HTMLConverter()
        let rawHtml = converter.convert(attributedText.rootNode())

        return rawHtml
    }


    /// Loads a given HTML String, and converts it into an Attributed String (WYSIWYG Mode)
    ///
    /// - Parameters:
    ///     - html: The raw HTML we'd be editing.
    ///
    public func loadHTML(html: String) {
        do {
            let defaultFontSize = CGFloat(12)
            let defaultFontDescriptor = UIFont.systemFontOfSize(defaultFontSize).fontDescriptor()
            let converter = HTMLToAttributedString(usingDefaultFontDescriptor: defaultFontDescriptor)
            attributedText = try converter.convert(html)
        } catch {
            fatalError("Couldn't convert HTML String:\n\(html)")
        }
    }
}
