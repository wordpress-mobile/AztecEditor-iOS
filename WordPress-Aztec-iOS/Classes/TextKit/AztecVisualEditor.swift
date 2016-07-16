import Foundation


/// AztecVisualEditor
///
public class AztecVisualEditor : NSObject
{

    let textView: UITextView
    var attachmentManager: AztecAttachmentManager!
    var storage: AztecTextStorage {
        return textView.textStorage as! AztecTextStorage
    }


    /// Returns a UITextView whose TextKit stack is composted to use AztecTextStorage.
    ///
    /// - Returns: A UITextView.
    ///
    public class func createTextView() -> UITextView {
        let storage = AztecTextStorage()
        let layoutManager = NSLayoutManager()
        let container = NSTextContainer()

        storage.addLayoutManager(layoutManager)
        layoutManager.addTextContainer(container)
        container.widthTracksTextView = true

        // Arbitrary starting frame.
        return UITextView(frame: CGRectMake(0, 0, 100, 44), textContainer: container)
    }


    public init(textView: UITextView) {
        assert(textView.textStorage.isKindOfClass(AztecTextStorage.self), "AztecVisualEditor should only be used with UITextView's backed by AztecTextStorage")

        self.textView = textView

        super.init()

        attachmentManager = AztecAttachmentManager(textView: textView, delegate: self)
        textView.layoutManager.delegate = self
    }


    // MARK: - Other Methods


    public func styleIdentifiersAtIndex(index: Int) -> [String] {
        var identifiers = [String]()

        if storage.length == 0 {
            return identifiers
        }

        let index = (storage.length < index) ? index : max(0, index - 1)

        if formattingAtIndexContainsBold(index) {
            identifiers.append(AztecFormattingIdentifier.Bold.rawValue)
        }
        if formattingAtIndexContainsItalic(index) {
            identifiers.append(AztecFormattingIdentifier.Italic.rawValue)
        }
        if formattingAtIndexContainsUnderline(index) {
            identifiers.append(AztecFormattingIdentifier.Underline.rawValue)
        }
        if formattingAtIndexContainsStrikethrough(index) {
            identifiers.append(AztecFormattingIdentifier.Strikethrough.rawValue)
        }

        return identifiers
    }


    // MARK: - Formatting


    /// Adds or removes a bold style from the specified range.
    ///
    public func toggleBold(range range: NSRange) {
        // Bail if nothing is selected
        if range.length == 0 {
            return
        }
        storage.toggleFontTrait(UIFontDescriptorSymbolicTraits.TraitBold, range: range)
    }


    /// Adds or removes a bold style from the specified range.
    ///
    public func toggleItalic(range range: NSRange) {
        // Bail if nothing is selected
        if range.length == 0 {
            return
        }
        storage.toggleFontTrait(UIFontDescriptorSymbolicTraits.TraitItalic, range: range)
    }


    /// Adds or removes a bold style from the specified range.
    ///
    public func toggleUnderline(range range: NSRange) {
        // Bail if nothing is selected
        if range.length == 0 {
            return
        }

        var assigning = true
        var effectiveRange = NSRange()
        if let attr = storage.attribute(NSUnderlineStyleAttributeName, atIndex: range.location, effectiveRange: &effectiveRange) {
            assigning = !NSEqualRanges(range, effectiveRange)
        }

        // TODO: This is a bit tricky as we can collide with a link style.  We'll want to check for that and correct the style if necessary.
        if assigning {
            storage.addAttribute(NSUnderlineStyleAttributeName, value: NSUnderlineStyle.StyleSingle.rawValue, range: range)
        } else {
            storage.removeAttribute(NSUnderlineStyleAttributeName, range: range)
        }
    }


    /// Adds or removes a bold style from the specified range.
    ///
    public func toggleStrikethrough(range range: NSRange) {
        // Bail if nothing is selected
        if range.length == 0 {
            return
        }

        var assigning = true
        var effectiveRange = NSRange()
        if let attr = storage.attribute(NSStrikethroughStyleAttributeName, atIndex: range.location, effectiveRange: &effectiveRange) {
            assigning = !NSEqualRanges(range, effectiveRange)
        }

        if assigning {
            storage.addAttribute(NSStrikethroughStyleAttributeName, value: NSUnderlineStyle.StyleSingle.rawValue, range: range)
        } else {
            storage.removeAttribute(NSStrikethroughStyleAttributeName, range: range)
        }
    }


    /// Adds or removes a bold style from the specified range.
    ///
    public func toggleOrderedList(range range: NSRange) {
        print("ordered")
    }


    /// Adds or removes a bold style from the specified range.
    ///
    public func toggleUnorderedList(range range: NSRange) {
        print("unordered")
    }


    /// Adds or removes a bold style from the specified range.
    ///
    public func toggleBlockquote(range range: NSRange) {
        print("quote")
    }


    /// Adds or removes a bold style from the specified range.
    ///
    public func toggleLink(range range: NSRange, params: [String: AnyObject]) {
        print("link")
    }


    // MARK: - Embeds


    /// Inserts an image at the specified index
    ///
    public func insertImage(index: Int, params: [String: AnyObject]) {
        print("image")
    }


    /// Inserts a Video attachment at the specified index
    ///
    public func insertVideo(index: Int, params: [String: AnyObject]) {
        print("video")
    }


    // MARK - Inspectors


    public func formattingAtIndexContainsBold(index: Int) -> Bool {
        return fontTrait(.TraitBold, existsAtIndex: index)
    }


    public func formattingAtIndexContainsItalic(index: Int) -> Bool {
        return fontTrait(.TraitItalic, existsAtIndex: index)
    }


    public func fontTrait(trait: UIFontDescriptorSymbolicTraits, existsAtIndex index: Int) -> Bool {
        guard let attr = storage.attribute(NSFontAttributeName, atIndex: index, effectiveRange: nil) else {
            return false
        }
        if let font = attr as? UIFont {
            return font.fontDescriptor().symbolicTraits.contains(trait)
        }
        return false
    }


    public func formattingAtIndexContainsUnderline(index: Int) -> Bool {
        guard let attr = storage.attribute(NSUnderlineStyleAttributeName, atIndex: index, effectiveRange: nil) else {
            return false
        }
        // TODO: Figure out how to reconcile this with Link style.
        if let style = attr as? NSUnderlineStyle {
            return style == NSUnderlineStyle.StyleSingle
        }
        return false
    }


    public func formattingAtIndexContainsStrikethrough(index: Int) -> Bool {
        guard let attr = storage.attribute(NSStrikethroughStyleAttributeName, atIndex: index, effectiveRange: nil) else {
            return false
        }
        if let style = attr as? NSUnderlineStyle {
            return style == NSUnderlineStyle.StyleSingle
        }
        return false
    }

}


/// Stubs an NSLayoutManagerDelegate
///
extension AztecVisualEditor: NSLayoutManagerDelegate
{

}


/// Stubs an AztecAttachmentManagerDelegate
///
extension AztecVisualEditor: AztecAttachmentManagerDelegate
{
    public func attachmentManager(attachmentManager: AztecAttachmentManager, viewForAttachment attachment: AztecTextAttachment) -> UIView? {
        return nil
    }
}
