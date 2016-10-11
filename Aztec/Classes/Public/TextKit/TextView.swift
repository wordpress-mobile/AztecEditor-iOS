import UIKit
import Gridicons

public protocol TextViewMediaDelegate: class {

    /// This method requests from the delegate the image at the specified URL.
    ///
    /// - Parameters:
    ///     - textView: the `TextView` the call has been made from.
    ///     - url: the url to download the image from.
    ///     - success: when the image is obtained, this closure should be executed.
    ///     - failure: if the image cannot be obtained, this closure should be executed.
    ///
    /// - Returns: the placeholder for the requested image.  Also useful if showing low-res versions
    ///         of the images.
    ///
    func image(forTextView textView: TextView, atUrl url: NSURL, onSuccess success: UIImage -> Void, onFailure failure: Void -> Void) -> UIImage
}

public class TextView: UITextView {

    typealias ElementNode = Libxml2.ElementNode


    // MARK: - Properties: Attachments & Media

    /// The media delegate takes care of providing remote media when requested by the `TextView`.
    /// If this is not set, all remove images will be left blank.
    ///
    public weak var mediaDelegate: TextViewMediaDelegate? = nil

    // MARK: - Properties: GUI Defaults

    let defaultFont: UIFont
    var defaultMissingImage: UIImage

    // MARK: - Properties: Text Storage

    var storage: TextStorage {
        return textStorage as! TextStorage
    }

    // MARK: - Init & deinit

    public init(defaultFont: UIFont, defaultMissingImage: UIImage) {
        let storage = TextStorage()
        let layoutManager = NSLayoutManager()
        let container = NSTextContainer()

        self.defaultFont = defaultFont
        self.defaultMissingImage = defaultMissingImage

        storage.addLayoutManager(layoutManager)
        layoutManager.addTextContainer(container)
        container.widthTracksTextView = true

        super.init(frame: CGRect(x: 0, y: 0, width: 10, height: 10), textContainer: container)
        
        allowsEditingTextAttributes = true
        storage.imageProvider = self
    }

    required public init?(coder aDecoder: NSCoder) {

        defaultFont = UIFont.systemFontOfSize(14)
        defaultMissingImage = Gridicon.iconOfType(.Image)

        super.init(coder: aDecoder)
        
        allowsEditingTextAttributes = true
    }


    // MARK: - UIView Overrides

    public override func didMoveToWindow() {
        super.didMoveToWindow()
        layoutIfNeeded()
    }

    // MARK: - Paragraphs

    /// Get the default paragraph style for the editor.
    ///
    /// - Returns: The default paragraph style.
    ///
    func defaultParagraphStyle() -> NSParagraphStyle {
        // TODO: We need to implement this properly, Just stubbed for now.
        return NSParagraphStyle()
    }


    /// Get the ranges of paragraphs that encompase the specified range.
    ///
    /// - Parameters:
    ///     - range: The specified NSRange.
    ///
    /// - Returns an array of NSRange objects.
    ///
    func rangesOfParagraphsEnclosingRange(range: NSRange) -> [NSRange] {
        var paragraphRanges = [NSRange]()
        let string = storage.string as NSString
        string.enumerateSubstringsInRange(NSRange(location: 0, length: string.length),
                                          options: .ByParagraphs,
                                          usingBlock: { (substring, substringRange, enclosingRange, stop) in
                                            // Stop if necessary.
                                            if substringRange.location > NSMaxRange(range) {
                                                stop.memory = true
                                                return
                                            }

                                            // Bail early if the paragraph precedes the start of the selection
                                            if NSMaxRange(substringRange) < range.location {
                                                return
                                            }

                                            paragraphRanges.append(substringRange)
        })
        return paragraphRanges
    }

    // MARK: - HTML Interaction

    /// Converts the current Attributed Text into a raw HTML String
    ///
    /// - Returns: The HTML version of the current Attributed String.
    ///
    public func getHTML() -> String {
        return storage.getHTML()
    }


    /// Loads the specified HTML into the editor.
    ///
    /// - Parameters:
    ///     - html: The raw HTML we'd be editing.
    ///
    public func setHTML(html: String) {
        
        // NOTE: there's a bug in UIKit that causes the textView's font to be changed under certain
        //      conditions.  We are assigning the default font here again to avoid that issue.
        //
        //      More information about the bug here:
        //          https://github.com/wordpress-mobile/WordPress-Aztec-iOS/issues/58
        //
        //font = defaultFont
        
        storage.setHTML(html, withDefaultFontDescriptor: font!.fontDescriptor())
    }


    // MARK: - Getting format identifiers


    /// Get a list of format identifiers spanning the specified range as a String array.
    ///
    /// - Parameters:
    ///     - range: An NSRange to inspect.
    ///
    /// - Returns: A list of identifiers.
    ///
    public func formatIdentifiersSpanningRange(range: NSRange) -> [String] {
        guard storage.length != 0 else {
            return []
        }

        if range.length == 0 {
            return formatIdentifiersAtIndex(range.location)
        }

        var identifiers = [FormattingIdentifier]()

        if boldFormattingSpansRange(range) {
            identifiers.append(.Bold)
        }

        if italicFormattingSpansRange(range) {
            identifiers.append(.Italic)
        }

        if underlineFormattingSpansRange(range) {
            identifiers.append(.Underline)
        }

        if strikethroughFormattingSpansRange(range) {
            identifiers.append(.Strikethrough)
        }

        if linkFormattingSpansRange(range) {
            identifiers.append(.Link)
        }

        if orderedListFormattingSpansRange(range) {
            identifiers.append(.Orderedlist)
        }

        if unorderedListFormattingSpansRange(range) {
            identifiers.append(.Unorderedlist)
        }

        return identifiers.map { $0.rawValue }
    }


    /// Get a list of format identifiers at a specific index as a String array.
    ///
    /// - Parameters:
    ///     - range: The character index to inspect.
    ///
    /// - Returns: A list of identifiers.
    ///
    public func formatIdentifiersAtIndex(index: Int) -> [String] {
        guard storage.length != 0 else {
            return []
        }

        let index = adjustedIndex(index)
        var identifiers = [FormattingIdentifier]()

        if formattingAtIndexContainsBold(index) {
            identifiers.append(.Bold)
        }

        if formattingAtIndexContainsItalic(index) {
            identifiers.append(.Italic)
        }

        if formattingAtIndexContainsUnderline(index) {
            identifiers.append(.Underline)
        }

        if formattingAtIndexContainsStrikethrough(index) {
            identifiers.append(.Strikethrough)
        }

        if formattingAtIndexContainsBlockquote(index) {
            identifiers.append(.Blockquote)
        }

        if formattingAtIndexContainsLink(index) {
            identifiers.append(.Link)
        }

        if formattingAtIndexContainsOrderedList(index) {
            identifiers.append(.Orderedlist)
        }

        if formattingAtIndexContainsUnorderedList(index) {
            identifiers.append(.Unorderedlist)
        }

        return identifiers.map { $0.rawValue }
    }


    // MARK: - Formatting


    /// Adds or removes a bold style from the specified range.
    ///
    /// - Parameters:
    ///     - range: The NSRange to edit.
    ///
    public func toggleBold(range range: NSRange) {
        guard range.length > 0 else {
            return
        }

        storage.toggleBold(range)
    }


    /// Adds or removes a italic style from the specified range.
    ///
    /// - Parameters:
    ///     - range: The NSRange to edit.
    ///
    public func toggleItalic(range range: NSRange) {
        guard range.length > 0 else {
            return
        }

        storage.toggleItalic(range)
    }


    /// Adds or removes a underline style from the specified range.
    ///
    /// - Parameters:
    ///     - range: The NSRange to edit.
    ///
    public func toggleUnderline(range range: NSRange) {
        guard range.length > 0 else {
            return
        }

        storage.toggleUnderlineForRange(range)
    }


    /// Adds or removes a strikethrough style from the specified range.
    ///
    /// - Parameters:
    ///     - range: The NSRange to edit.
    ///
    public func toggleStrikethrough(range range: NSRange) {
        guard range.length > 0 else {
            return
        }

        storage.toggleStrikethrough(range)
    }


    /// Adds or removes a ordered list style from the specified range.
    ///
    /// - Parameters:
    ///     - range: The NSRange to edit.
    ///
    public func toggleOrderedList(range range: NSRange) {
        let listRange = rangeForTextList(range)
        let formatter = TextListFormatter()
        formatter.toggleList(ofStyle: .Ordered, inString: storage, atRange: listRange)
// TODO: Update selected range
    }


    /// Adds or removes a unordered list style from the specified range.
    ///
    /// - Parameters:
    ///     - range: The NSRange to edit.
    ///
    public func toggleUnorderedList(range range: NSRange) {
        let listRange = rangeForTextList(range)
        let formatter = TextListFormatter()
        formatter.toggleList(ofStyle: .Unordered, inString: storage, atRange: listRange)
// TODO: Update selected range
    }


    /// Adds or removes a blockquote style from the specified range.
    /// Blockquotes are applied to an entire paragrah regardless of the range.
    /// If the range spans multiple paragraphs, the style is applied to all
    /// affected paragraphs.
    ///
    /// - Parameters:
    ///     - range: The NSRange to edit.
    ///
    public func toggleBlockquote(range range: NSRange) {
        let storage = textStorage

        // Check if the start of the selection is already in a blockquote.
        let addingStyle = !formattingAtIndexContainsBlockquote(range.location)

        // Get the affected paragraphs
        let paragraphRanges = rangesOfParagraphsEnclosingRange(range)
        guard let firstRange = paragraphRanges.first else {
            return
        }

        // Compose the range for the blockquote.
        var length = 0
        for range in paragraphRanges {
            length += range.length
        }
        let blockquoteRange = NSRange(location: firstRange.location, length: length)

        // TODO: Assign or remove the blockquote custom attribute.


        // Add or remove indentation as needed.
        // First get the list of pristine ranges to edit. We do this so
        // a modification doesn't impact the next returned range as paragraph
        // styles can be apparently merged to a single range in some cases.
        var rangesToStyle = [NSRange]()
        storage.enumerateAttribute(NSParagraphStyleAttributeName,
                                   inRange: blockquoteRange,
                                   options: [],
                                   usingBlock: { (value, range, stop) in
                                    rangesToStyle.append(range)
        })
        // Now loop over our pristine ranges knowing that any edits won't impact
        // subsquent ranges.
        for range in rangesToStyle {
            let value = storage.attribute(NSParagraphStyleAttributeName, atIndex: range.location, effectiveRange: nil)
            let style = value as? NSParagraphStyle ?? defaultParagraphStyle()

            var tab: CGFloat = 0
            if addingStyle {
                tab = min(style.headIndent + Metrics.defaultIndentation, Metrics.maxIndentation)
            } else {
                tab = max(0, style.headIndent - Metrics.defaultIndentation)
            }

            let newStyle = NSMutableParagraphStyle()
            newStyle.setParagraphStyle(style)
            newStyle.headIndent = tab
            newStyle.firstLineHeadIndent = tab

            storage.addAttribute(NSParagraphStyleAttributeName, value: newStyle, range: range)
        }
    }


    /// Adds a link to the designated url on the specified range.
    ///
    /// - Parameters:
    ///     - url: the NSURL to link to.
    ///     - title: the text for the link
    ///     - range: The NSRange to edit.
    public func setLink(url: NSURL, title: String, inRange range: NSRange) {
        let index = range.location
        let length = title.characters.count
        let insertionRange = NSMakeRange(index, length)
        storage.replaceCharactersInRange(range, withString: title)
        storage.setLink(url, forRange: insertionRange)
    }

    public func removeLink(inRange range:NSRange) {
        storage.removeLink(inRange: range)
    }

    // MARK: - Embeds

    /// Inserts an image at the specified index
    ///
    /// - Parameters:
    ///     - image: the image object to be inserted.
    ///     - sourceURL: The url of the image to be inserted.
    ///     - position: The character index at which to insert the image.
    ///
    public func insertImage(sourceURL url: NSURL, atPosition position: Int, placeHolderImage: UIImage?) {
        storage.insertImage(sourceURL: url, atPosition: position, placeHolderImage: placeHolderImage ?? defaultMissingImage)
        let length = NSAttributedString(attachment:NSTextAttachment()).length
        selectedRange = NSMakeRange(position+length, 0)
    }


    /// Inserts a Video attachment at the specified index
    ///
    /// - Parameters:
    ///     - index: The character index at which to insert the image.
    ///     - params: TBD
    ///
    public func insertVideo(index: Int, params: [String: AnyObject]) {
        print("video")
    }


    // MARK - Inspectors
    // MARK - Inspect Within Range


    /// Returns the associated TextAttachment, at a given point, if any.
    ///
    /// - Parameters:
    ///     - point: The point on screen to check for attachments.
    ///
    /// - Returns: The associated TextAttachment.
    ///
    public func attachmentAtPoint(point: CGPoint) -> TextAttachment? {
        let index = layoutManager.characterIndexForPoint(point, inTextContainer: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        guard index <= textStorage.length else {
            return nil
        }

        return textStorage.attribute(NSAttachmentAttributeName, atIndex: index, effectiveRange: nil) as? TextAttachment
    }


    /// Check if the bold attribute spans the specified range.
    ///
    /// - Parameters:
    ///     - range: The NSRange to inspect.
    ///
    /// - Returns: True if the attribute spans the entire range.
    ///
    public func boldFormattingSpansRange(range: NSRange) -> Bool {
        return storage.fontTrait(.TraitBold, spansRange: range)
    }


    /// Check if the italic attribute spans the specified range.
    ///
    /// - Parameters:
    ///     - range: The NSRange to inspect.
    ///
    /// - Returns: True if the attribute spans the entire range.
    ///
    public func italicFormattingSpansRange(range: NSRange) -> Bool {
        return storage.fontTrait(.TraitItalic, spansRange: range)
    }


    /// Check if the underline attribute spans the specified range.
    ///
    /// - Parameters:
    ///     - range: The NSRange to inspect.
    ///
    /// - Returns: True if the attribute spans the entire range.
    ///
    public func underlineFormattingSpansRange(range: NSRange) -> Bool {
        let index = maxIndex(range.location)
        var effectiveRange = NSRange()
        guard let attribute = storage.attribute(NSUnderlineStyleAttributeName, atIndex: index, effectiveRange: &effectiveRange) as? Int else {
            return false
        }

        return attribute == NSUnderlineStyle.StyleSingle.rawValue && NSEqualRanges(range, NSIntersectionRange(range, effectiveRange))
    }


    /// Check if the strikethrough attribute spans the specified range.
    ///
    /// - Parameters:
    ///     - range: The NSRange to inspect.
    ///
    /// - Returns: True if the attribute spans the entire range.
    ///
    public func strikethroughFormattingSpansRange(range: NSRange) -> Bool {
        let index = maxIndex(range.location)
        var effectiveRange = NSRange()
        guard let attribute = storage.attribute(NSStrikethroughStyleAttributeName, atIndex: index, effectiveRange: &effectiveRange) as? Int else {
            return false
        }

        return attribute == NSUnderlineStyle.StyleSingle.rawValue && NSEqualRanges(range, NSIntersectionRange(range, effectiveRange))
    }

    /// Check if the link attribute spans the specified range.
    ///
    /// - Parameters:
    ///     - range: The NSRange to inspect.
    ///
    /// - Returns: True if the attribute spans the entire range.
    ///
    public func linkFormattingSpansRange(range: NSRange) -> Bool {
        let index = maxIndex(range.location)
        var effectiveRange = NSRange()
        if storage.attribute(NSLinkAttributeName, atIndex: index, effectiveRange: &effectiveRange) != nil {

           return NSEqualRanges(range, NSIntersectionRange(range, effectiveRange))
        }
        return false
    }


    /// Check if an ordered list spans the specified range.
    ///
    /// - Parameters:
    ///     - range: The NSRange to inspect.
    ///
    /// - Returns: True if the attribute spans the entire range.
    ///
    public func orderedListFormattingSpansRange(range: NSRange) -> Bool {
        return storage.textListAttribute(spanningRange: range)?.style == .Ordered
    }


    /// Check if an unordered list spans the specified range.
    ///
    /// - Parameter range: The NSRange to inspect.
    ///
    /// - Returns: True if the attribute spans the entire range.
    ///
    public func unorderedListFormattingSpansRange(range: NSRange) -> Bool {
        return storage.textListAttribute(spanningRange: range)?.style == .Unordered
    }


    /// Returns an NSURL if the specified range as attached a link attribute
    ///
    /// - Parameter range: The NSRange to inspect
    ///
    /// - returns: the NSURL if available
    ///
    public func linkURL(forRange range: NSRange) -> NSURL? {
        let index = maxIndex(range.location)
        var effectiveRange = NSRange()
        if let attr = storage.attribute(NSLinkAttributeName, atIndex: index, effectiveRange: &effectiveRange) {
            if let url = attr as? NSURL {
                return url
            } else if let urlString = attr as? String {
                return NSURL(string:urlString)
            }
        }
        return nil
    }

    public func linkFullRange(forRange range: NSRange) -> NSRange? {
        let index = maxIndex(range.location)
        var effectiveRange = NSRange()
        if storage.attribute(NSLinkAttributeName, atIndex: index, effectiveRange: &effectiveRange) != nil {
            return effectiveRange
        }
        return nil
    }

    /// Check if the blockquote attribute spans the specified range.
    ///
    /// - Parameters:
    ///     - range: The NSRange to inspect.
    ///
    /// - Returns: True if the attribute spans the entire range.
    ///
    public func blockquoteFormattingSpansRange(range: NSRange) -> Bool {
        let index = maxIndex(range.location)
        var effectiveRange = NSRange()
        guard let attribute = storage.attribute(NSParagraphStyleAttributeName, atIndex: index, effectiveRange: &effectiveRange) as? NSParagraphStyle else {
            return false
        }

        return attribute.headIndent == Metrics.defaultIndentation && NSEqualRanges(range, NSIntersectionRange(range, effectiveRange))
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


    /// TextListFormatter was designed to be applied over a range of text. Whenever such range is
    /// zero, we may have trouble determining where to apply the list. For that reason,
    /// whenever the list range's length is zero, we'll attempt to infer the range of the line at
    /// which the cursor is located.
    ///
    /// - Parameters:
    ///     - range: The NSRange in which a TextList should be applied
    ///
    /// Returns: A corrected NSRange, if the original one had empty length.
    ///
    func rangeForTextList(range: NSRange) -> NSRange {
        guard range.length == 0 else {
            return range
        }

        return storage.rangeOfLine(atIndex: range.location) ?? range
    }


    // MARK - Inspect at Index


    /// Check if the bold attribute exists at the specified index.
    ///
    /// - Parameters:
    ///     - index: The character index to inspect.
    ///
    /// - Returns: True if the attribute exists at the specified index.
    ///
    public func formattingAtIndexContainsBold(index: Int) -> Bool {
        return storage.fontTrait(.TraitBold, existsAtIndex: index)
    }


    /// Check if the italic attribute exists at the specified index.
    ///
    /// - Parameters:
    ///     - index: The character index to inspect.
    ///
    /// - Returns: True if the attribute exists at the specified index.
    ///
    public func formattingAtIndexContainsItalic(index: Int) -> Bool {
        return storage.fontTrait(.TraitItalic, existsAtIndex: index)
    }


    /// Check if the underline attribute exists at the specified index.
    ///
    /// - Parameters:
    ///     - index: The character index to inspect.
    ///
    /// - Returns: True if the attribute exists at the specified index.
    ///
    public func formattingAtIndexContainsUnderline(index: Int) -> Bool {
        guard let attribute = storage.attribute(NSUnderlineStyleAttributeName, atIndex: index, effectiveRange: nil) as? Int else {
            return false
        }
        // TODO: Figure out how to reconcile this with Link style.
        return attribute == NSUnderlineStyle.StyleSingle.rawValue
    }


    /// Check if the strikethrough attribute exists at the specified index.
    ///
    /// - Parameters:
    ///     - index: The character index to inspect.
    ///
    /// - Returns: True if the attribute exists at the specified index.
    ///
    public func formattingAtIndexContainsStrikethrough(index: Int) -> Bool {
        guard let attribute = storage.attribute(NSStrikethroughStyleAttributeName, atIndex: index, effectiveRange: nil) as? Int else {
            return false
        }

        return attribute == NSUnderlineStyle.StyleSingle.rawValue
    }

    /// Check if the link attribute exists at the specified index.
    ///
    /// - Parameters:
    ///     - index: The character index to inspect.
    ///
    /// - Returns: True if the attribute exists at the specified index.
    ///
    public func formattingAtIndexContainsLink(index: Int) -> Bool {
        guard storage.attribute(NSLinkAttributeName, atIndex: index, effectiveRange: nil) != nil else {
            return false
        }

        return true
    }

    
    /// Check if the blockquote attribute exists at the specified index.
    ///
    /// - Parameters:
    ///     - index: The character index to inspect.
    ///
    /// - Returns: True if the attribute exists at the specified index.
    ///
    public func formattingAtIndexContainsBlockquote(index: Int) -> Bool {
        guard let attr = storage.attribute(NSParagraphStyleAttributeName, atIndex: index, effectiveRange: nil) as? NSParagraphStyle else {
            return false
        }
        
        // TODO: This is very basic. We'll want to check for our custom blockquote attribute eventually.
        return attr.headIndent != 0
    }


    /// Check if an ordered list exists at the specified index.
    ///
    /// - Paramters:
    ///     - index: The character index to inspect.
    ///
    /// - Returns: True if the attribute exists at the specified index.
    ///
    public func formattingAtIndexContainsOrderedList(index: Int) -> Bool {
        return storage.textListAttribute(atIndex: index)?.style == .Ordered
    }


    /// Check if an unordered list exists at the specified index.
    ///
    /// - Paramters:
    ///     - index: The character index to inspect.
    ///
    /// - Returns: True if the attribute exists at the specified index.
    ///
    public func formattingAtIndexContainsUnorderedList(index: Int) -> Bool {
        return storage.textListAttribute(atIndex: index)?.style == .Unordered
    }


    // MARK: - Attachments

    public func changeAlignment(forAttachment attachment: TextAttachment, to alignment: TextAttachment.Alignment) {
        attachment.alignment = alignment

        storage.invalidateLayoutForAttachment(attachment)
    }

    public func changeSize(forAttachment attachment: TextAttachment, to size: TextAttachment.Size) {
        attachment.size = size

        storage.invalidateLayoutForAttachment(attachment)
    }
}

// MARK: - TextStorageAttachmentsDelegate

extension TextView: TextStorageImageProvider {

    func storage(storage: TextStorage, attachment: TextAttachment, imageForURL url: NSURL, onSuccess success: (UIImage) -> (), onFailure failure: () -> ()) -> UIImage {
        if let mediaDelegate = mediaDelegate {
            let placeholderImage = mediaDelegate.image(forTextView: self, atUrl: url, onSuccess: success, onFailure: failure)
            return placeholderImage
        } else {
            return Gridicon.iconOfType(.Attachment)
        }
    }

    func storage(storage: TextStorage, missingImageForAttachment: TextAttachment) -> UIImage {
        return defaultMissingImage
    }
}
