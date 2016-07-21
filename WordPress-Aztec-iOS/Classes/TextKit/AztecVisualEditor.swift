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


    // MARK: - Lifecycle Methods


    public init(textView: UITextView) {
        assert(textView.textStorage.isKindOfClass(AztecTextStorage.self), "AztecVisualEditor should only be used with UITextView's backed by AztecTextStorage")

        self.textView = textView

        super.init()

        attachmentManager = AztecAttachmentManager(textView: textView, delegate: self)
        textView.layoutManager.delegate = self
    }


    // MARK: - Getting format identifiers


    /// Get a list of format identifiers spanning the specified range as a String array.
    ///
    /// - Paramters:
    ///     - range: An NSRange to inspect.
    ///
    /// - Returns: A list of identifiers.
    ///
    public func formatIdentifiersSpanningRange(range: NSRange) -> [String] {
        var identifiers = [String]()

        if storage.length == 0 {
            return identifiers
        }

        if range.length == 0 {
            return formatIdentifiersAtIndex(range.location)
        }

        if boldFormattingSpansRange(range) {
            identifiers.append(AztecFormattingIdentifier.Bold.rawValue)
        }

        if italicFormattingSpansRange(range) {
            identifiers.append(AztecFormattingIdentifier.Italic.rawValue)
        }

        if underlineFormattingSpansRange(range) {
            identifiers.append(AztecFormattingIdentifier.Underline.rawValue)
        }

        if strikethroughFormattingSpansRange(range) {
            identifiers.append(AztecFormattingIdentifier.Strikethrough.rawValue)
        }

        return identifiers
    }


    /// Get a list of format identifiers at a specific index as a String array.
    ///
    /// - Paramters:
    ///     - range: The character index to inspect.
    ///
    /// - Returns: A list of identifiers.
    ///
    public func formatIdentifiersAtIndex(index: Int) -> [String] {
        var identifiers = [String]()

        if storage.length == 0 {
            return identifiers
        }

        let index = adjustedIndex(index)

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
    /// - Paramters:
    ///     - range: The NSRange to edit.
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
    /// - Paramters:
    ///     - range: The NSRange to edit.
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
    /// - Paramters:
    ///     - range: The NSRange to edit.
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
    /// - Paramters:
    ///     - range: The NSRange to edit.
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
    /// - Paramters:
    ///     - range: The NSRange to edit.
    ///
    public func toggleOrderedList(range range: NSRange) {
        print("ordered")
    }


    /// Adds or removes a bold style from the specified range.
    ///
    /// - Paramters:
    ///     - range: The NSRange to edit.
    ///
    public func toggleUnorderedList(range range: NSRange) {
        print("unordered")
    }


    /// Adds or removes a bold style from the specified range.
    ///
    /// - Paramters:
    ///     - range: The NSRange to edit.
    ///
    public func toggleBlockquote(range range: NSRange) {
        print("quote")
    }


    /// Adds or removes a bold style from the specified range.
    ///
    /// - Paramters:
    ///     - range: The NSRange to edit.
    ///
    public func toggleLink(range range: NSRange, params: [String: AnyObject]) {
        print("link")
    }


    // MARK: - Embeds


    /// Inserts an image at the specified index
    ///
    /// - Paramters:
    ///     - index: The character index at which to insert the image.
    ///     - params: TBD
    ///
    public func insertImage(index: Int, params: [String: AnyObject]) {
        print("image")
    }


    /// Inserts a Video attachment at the specified index
    ///
    /// - Paramters:
    ///     - index: The character index at which to insert the image.
    ///     - params: TBD
    ///
    public func insertVideo(index: Int, params: [String: AnyObject]) {
        print("video")
    }


    // MARK - Inspectors
    // MARK - Inspect Within Range


    /// Check if the bold attribute spans the specified range.
    ///
    /// - Paramters:
    ///     - range: The NSRange to inspect.
    ///
    /// - Returns: True if the attribute spans the entire range.
    ///
    public func boldFormattingSpansRange(range: NSRange) -> Bool {
        return storage.fontTrait(.TraitBold, spansRange: range)
    }


    /// Check if the italic attribute spans the specified range.
    ///
    /// - Paramters:
    ///     - range: The NSRange to inspect.
    ///
    /// - Returns: True if the attribute spans the entire range.
    ///
    public func italicFormattingSpansRange(range: NSRange) -> Bool {
        return storage.fontTrait(.TraitItalic, spansRange: range)
    }


    /// Check if the underline attribute spans the specified range.
    ///
    /// - Paramters:
    ///     - range: The NSRange to inspect.
    ///
    /// - Returns: True if the attribute spans the entire range.
    ///
    public func underlineFormattingSpansRange(range: NSRange) -> Bool {
        let index = maxIndex(range.location)
        var effectiveRange = NSRange()
        if let attr = storage.attribute(NSUnderlineStyleAttributeName, atIndex: index, effectiveRange: &effectiveRange),
            let value = attr as? Int {

            return value == NSUnderlineStyle.StyleSingle.rawValue && NSEqualRanges(range, NSIntersectionRange(range, effectiveRange))
        }
        return false
    }


    /// Check if the strikethrough attribute spans the specified range.
    ///
    /// - Paramters:
    ///     - range: The NSRange to inspect.
    ///
    /// - Returns: True if the attribute spans the entire range.
    ///
    public func strikethroughFormattingSpansRange(range: NSRange) -> Bool {
        let index = maxIndex(range.location)
        var effectiveRange = NSRange()
        if let attr = storage.attribute(NSStrikethroughStyleAttributeName, atIndex: index, effectiveRange: &effectiveRange),
            let value = attr as? Int {

            return value == NSUnderlineStyle.StyleSingle.rawValue && NSEqualRanges(range, NSIntersectionRange(range, effectiveRange))
        }
        return false
    }


    /// The maximum index should never exceed the length of the text storage minus one,
    /// else we court out of index exceptions.
    ///
    /// - Parameters:
    ///     - index: The candidate index. If the index is greater than the max allowed, the max is returned.
    ///
    /// - Returns: If the index is greater than the max allowed, the max is returned, else the original value.
    ///
    func maxIndex(index: Int) -> Int {
        if index >= storage.length {
            return storage.length - 1
        }
        return index
    }


    /// In most instances, the value of NSRange.location is off by one when compared to a character index. 
    /// Call this method to get an adjusted character index from an NSRange.location.
    ///
    /// - Parameters:
    ///     - index: The candidate index.
    ///
    /// - Returns: The specified or maximum index.
    ///
    func adjustedIndex(index: Int) -> Int {
        let index = maxIndex(index)
        return max(0, index - 1)
    }


    // MARK - Inspect at Index


    /// Check if the bold attribute exists at the specified index.
    ///
    /// - Paramters:
    ///     - index: The character index to inspect.
    ///
    /// - Returns: True if the attribute exists at the specified index.
    ///
    public func formattingAtIndexContainsBold(index: Int) -> Bool {
        return storage.fontTrait(.TraitBold, existsAtIndex: index)
    }


    /// Check if the italic attribute exists at the specified index.
    ///
    /// - Paramters:
    ///     - index: The character index to inspect.
    ///
    /// - Returns: True if the attribute exists at the specified index.
    ///
    public func formattingAtIndexContainsItalic(index: Int) -> Bool {
        return storage.fontTrait(.TraitItalic, existsAtIndex: index)
    }


    /// Check if the underline attribute exists at the specified index.
    ///
    /// - Paramters:
    ///     - index: The character index to inspect.
    ///
    /// - Returns: True if the attribute exists at the specified index.
    ///
    public func formattingAtIndexContainsUnderline(index: Int) -> Bool {
        guard let attr = storage.attribute(NSUnderlineStyleAttributeName, atIndex: index, effectiveRange: nil) else {
            return false
        }
        // TODO: Figure out how to reconcile this with Link style.
        if let value = attr as? Int {
            return value == NSUnderlineStyle.StyleSingle.rawValue
        }
        return false
    }


    /// Check if the strikethrough attribute exists at the specified index.
    ///
    /// - Paramters:
    ///     - index: The character index to inspect.
    ///
    /// - Returns: True if the attribute exists at the specified index.
    ///
    public func formattingAtIndexContainsStrikethrough(index: Int) -> Bool {
        guard let attr = storage.attribute(NSStrikethroughStyleAttributeName, atIndex: index, effectiveRange: nil) else {
            return false
        }
        if let value = attr as? Int {
            return value == NSUnderlineStyle.StyleSingle.rawValue
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
