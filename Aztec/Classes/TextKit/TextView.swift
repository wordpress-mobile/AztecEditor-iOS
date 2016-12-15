
import UIKit
import Gridicons

public protocol TextViewMediaDelegate: class {

    /// This method requests from the delegate the image at the specified URL.
    ///
    /// - Parameters:
    ///     - textView: the `TextView` the call has been made from.
    ///     - imageURL: the url to download the image from.
    ///     - success: when the image is obtained, this closure should be executed.
    ///     - failure: if the image cannot be obtained, this closure should be executed.
    ///
    /// - Returns: the placeholder for the requested image.  Also useful if showing low-res versions
    ///         of the images.
    ///
    func textView(
        _ textView: TextView,
        imageAtUrl imageURL: URL,
        onSuccess success: @escaping (UIImage) -> Void,
        onFailure failure: @escaping (Void) -> Void) -> UIImage
    
    func textView(
        _ textView: TextView,
        urlForImage image: UIImage) -> URL
}

open class TextView: UITextView {

    typealias ElementNode = Libxml2.ElementNode


    // MARK: - Properties: Attachments & Media

    /// The media delegate takes care of providing remote media when requested by the `TextView`.
    /// If this is not set, all remove images will be left blank.
    ///
    open weak var mediaDelegate: TextViewMediaDelegate? = nil

    // MARK: - Properties: GUI Defaults

    let defaultFont: UIFont
    var defaultMissingImage: UIImage

    // MARK: - Properties: Text Storage

    var storage: TextStorage {
        return textStorage as! TextStorage
    }

    // MARK: - Init & deinit

    public init(defaultFont: UIFont, defaultMissingImage: UIImage) {
        
        self.defaultFont = defaultFont
        self.defaultMissingImage = defaultMissingImage
        
        let storage = TextStorage()
        let layoutManager = LayoutManager()
        let container = NSTextContainer()

        storage.addLayoutManager(layoutManager)
        layoutManager.addTextContainer(container)
        container.widthTracksTextView = true
        
        super.init(frame: CGRect(x: 0, y: 0, width: 10, height: 10), textContainer: container)
        storage.undoManager = undoManager
        commonInit()
        setupMenuController()
    }
    
    required public init?(coder aDecoder: NSCoder) {

        defaultFont = UIFont.systemFont(ofSize: 14)
        defaultMissingImage = Gridicon.iconOfType(.image)
        super.init(coder: aDecoder)
        commonInit()
        setupMenuController()
    }

    private func commonInit() {
        allowsEditingTextAttributes = true
        storage.attachmentsDelegate = self
        font = defaultFont
    }

    private func setupMenuController() {
        let pasteAndMatchTitle = NSLocalizedString("Paste and Match Style", comment: "Paste and Match Menu Item")
        let pasteAndMatchItem = UIMenuItem(title: pasteAndMatchTitle, action: #selector(pasteAndMatchStyle))
        UIMenuController.shared.menuItems = [pasteAndMatchItem]
    }


    // MARK: - Intersect copy paste operations

    open override func copy(_ sender: Any?) {
        super.copy(sender)
        let data = self.storage.attributedSubstring(from: selectedRange).archivedData()
        let pasteboard  = UIPasteboard.general
        var items = pasteboard.items
        items[0][NSAttributedString.pastesboardUTI] = data
        pasteboard.items = items
    }

    open override func paste(_ sender: Any?) {
        let pasteboard  = UIPasteboard.general
        if let data = pasteboard.value(forPasteboardType: NSAttributedString.pastesboardUTI) as? Data,
           let aztecString = NSAttributedString.unarchive(with: data) {
            storage.replaceCharacters(in: selectedRange, with: aztecString)
        } else {
            super.paste(sender)
        }
    }

    open func pasteAndMatchStyle(_ sender: Any?) {
        guard let plainString = UIPasteboard.general.string, plainString.isEmpty == false else {
            super.paste(sender)
            return
        }

        storage.replaceCharacters(in: selectedRange, with: plainString)
    }

    // MARK: - Intersect keyboard operations

    open override func insertText(_ text: String) {
        var insertionRange = selectedRange
        super.insertText(text)
        insertionRange.length = 1
        refreshListAfterInsertionOf(text: text, range: insertionRange)
        refreshBlockquoteAfterInsertionOf(text: text, range: insertionRange)
    }

    open override func deleteBackward() {
        var deletionRange = selectedRange
        var deletedString = NSAttributedString()
        if deletionRange.length == 0 {
            deletionRange.location = max(selectedRange.location - 1, 0)
            deletionRange.length = 1
        }
        if storage.length > 0 {
            deletedString = storage.attributedSubstring(from: deletionRange)
        }

        super.deleteBackward()

        if storage.string.isEmpty {
            return
        }

        refreshListAfterDeletionOf(text: deletedString, atRange: deletionRange)
        refreshBlockquoteAfterDeletionOf(text: deletedString, atRange: deletionRange)
    }

    // MARK: - UIView Overrides

    open override func didMoveToWindow() {
        super.didMoveToWindow()
        layoutIfNeeded()
    }

    // MARK: - UITextView Overrides

    open override func caretRect(for position: UITextPosition) -> CGRect {
        let characterIndex = offset(from: beginningOfDocument, to: position)
        var caretRect = super.caretRect(for: position)
        guard layoutManager.isValidGlyphIndex(characterIndex) else {
            return caretRect
        }
        let glyphIndex = layoutManager.glyphIndexForCharacter(at: characterIndex)
        let usedLineFragment = layoutManager.lineFragmentUsedRect(forGlyphAt: glyphIndex, effectiveRange: nil)
        if !usedLineFragment.isEmpty {
            caretRect.origin.y = usedLineFragment.origin.y + textContainerInset.top
            caretRect.size.height = usedLineFragment.size.height
        }
        return caretRect
    }

    // MARK: - Paragraphs

    /// Get the ranges of paragraphs that encompase the specified range.
    ///
    /// - Parameter range: The specified NSRange.
    ///
    /// - Returns an array of NSRange objects.
    ///
    func rangesOfParagraphsEnclosingRange(_ range: NSRange) -> [NSRange] {
        var paragraphRanges = [NSRange]()
        let string = storage.string as NSString
        string.enumerateSubstrings(in: NSRange(location: 0, length: string.length),
                                          options: .byParagraphs,
                                          using: { (substring, substringRange, enclosingRange, stop) in
                                            // Stop if necessary.
                                            if substringRange.location > NSMaxRange(range) {
                                                stop.pointee = true
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
    open func getHTML() -> String {
        return storage.getHTML()
    }


    /// Loads the specified HTML into the editor.
    ///
    /// - Parameter html: The raw HTML we'd be editing.
    ///
    open func setHTML(_ html: String) {
        
        // NOTE: there's a bug in UIKit that causes the textView's font to be changed under certain
        //      conditions.  We are assigning the default font here again to avoid that issue.
        //
        //      More information about the bug here:
        //          https://github.com/wordpress-mobile/WordPress-Aztec-iOS/issues/58
        //
        font = defaultFont
        
        storage.setHTML(html, withDefaultFontDescriptor: font!.fontDescriptor)
    }


    // MARK: - Getting format identifiers


    /// Get a list of format identifiers spanning the specified range as a String array.
    ///
    /// - Parameter range: An NSRange to inspect.
    ///
    /// - Returns: A list of identifiers.
    ///
    open func formatIdentifiersSpanningRange(_ range: NSRange) -> [FormattingIdentifier] {
        guard storage.length != 0 else {
            // FIXME: if empty string, check typingAttributes
            return []
        }

        if range.length == 0 {
            return formatIdentifiersAtIndex(range.location)
        }

        var identifiers = [FormattingIdentifier]()

        if boldFormattingSpansRange(range) {
            identifiers.append(.bold)
        }

        if italicFormattingSpansRange(range) {
            identifiers.append(.italic)
        }

        if underlineFormattingSpansRange(range) {
            identifiers.append(.underline)
        }

        if strikethroughFormattingSpansRange(range) {
            identifiers.append(.strikethrough)
        }

        if linkFormattingSpansRange(range) {
            identifiers.append(.link)
        }

        if orderedListFormattingSpansRange(range) {
            identifiers.append(.orderedlist)
        }

        if unorderedListFormattingSpansRange(range) {
            identifiers.append(.unorderedlist)
        }

        return identifiers
    }


    /// Get a list of format identifiers at a specific index as a String array.
    ///
    /// - Parameter range: The character index to inspect.
    ///
    /// - Returns: A list of identifiers.
    ///
    open func formatIdentifiersAtIndex(_ index: Int) -> [FormattingIdentifier] {
        guard storage.length != 0 else {
            return []
        }

        let index = adjustedIndex(index)
        var identifiers = [FormattingIdentifier]()

        if formattingAtIndexContainsBold(index) {
            identifiers.append(.bold)
        }

        if formattingAtIndexContainsItalic(index) {
            identifiers.append(.italic)
        }

        if formattingAtIndexContainsUnderline(index) {
            identifiers.append(.underline)
        }

        if formattingAtIndexContainsStrikethrough(index) {
            identifiers.append(.strikethrough)
        }

        if formattingAtIndexContainsBlockquote(index) {
            identifiers.append(.blockquote)
        }

        if formattingAtIndexContainsLink(index) {
            identifiers.append(.link)
        }

        if formattingAtIndexContainsOrderedList(index) {
            identifiers.append(.orderedlist)
        }

        if formattingAtIndexContainsUnorderedList(index) {
            identifiers.append(.unorderedlist)
        }

        return identifiers
    }


    /// Get a list of format identifiers of the Typing Attributes.
    ///
    /// - Returns: A list of Formatting Identifiers.
    ///
    open func formatIdentifiersForTypingAttributes() -> [FormattingIdentifier] {
        var identifiers = [FormattingIdentifier]()

        if typingAttributesContainsBold() {
            identifiers.append(.bold)
        }

        if typingAttributesContainsItalic() {
            identifiers.append(.italic)
        }

        if typingAttributesContainsUnderline() {
            identifiers.append(.underline)
        }

        if typingAttributesContainsStrikethrough() {
            identifiers.append(.strikethrough)
        }

        if typingAttributesContainsBlockquote() {
            identifiers.append(.blockquote)
        }

        if typingAttributesContainsOrderedList() {
            identifiers.append(.orderedlist)
        }

        if typingAttributesContainsUnorderedList() {
            identifiers.append(.unorderedlist)
        }

        if typingAttributesContainsLink() {
            identifiers.append(.link)
        }

        return identifiers
    }


    // MARK: - Formatting


    /// Adds or removes a bold style from the specified range.
    ///
    /// - Parameter range: The NSRange to edit.
    ///
    open func toggleBold(range: NSRange) {
        updateTypingFont(toggle: .traitBold)

        if range.length > 0 {
            storage.toggleBold(range)
        }
    }


    /// Adds or removes a italic style from the specified range.
    ///
    /// - Parameter range: The NSRange to edit.
    ///
    open func toggleItalic(range: NSRange) {
        updateTypingFont(toggle: .traitItalic)

        if range.length > 0 {
            storage.toggleItalic(range)
        }
    }


    /// Adds or removes a underline style from the specified range.
    ///
    /// - Parameter range: The NSRange to edit.
    ///
    open func toggleUnderline(range: NSRange) {
        updateTypingAttribute(toggle: NSUnderlineStyleAttributeName, value: NSUnderlineStyle.styleSingle.rawValue as AnyObject)

        if range.length > 0 {
            storage.toggleUnderlineForRange(range)
        }
    }


    /// Adds or removes a strikethrough style from the specified range.
    ///
    /// - Parameter range: The NSRange to edit.
    ///
    open func toggleStrikethrough(range: NSRange) {
        updateTypingAttribute(toggle: NSStrikethroughStyleAttributeName, value: NSUnderlineStyle.styleSingle.rawValue as AnyObject)

        if range.length > 0 {
            storage.toggleStrikethrough(range)
        }
    }


    // MARK: - Typing Attributes


    /// Toggles the specified Font Trait in the currently selected Typing Font.
    ///
    /// - Parameter trait: The Font Property that should be toggled.
    ///
    private func updateTypingFont(toggle traits: UIFontDescriptorSymbolicTraits) {
        guard let font = typingAttributes[NSFontAttributeName] as? UIFont else {
            return
        }

        let enabled = font.containsTraits(traits)
        let newFont = font.modifyTraits(traits, enable: !enabled)
        typingAttributes[NSFontAttributeName] = newFont
    }


    /// Toggles the specified Typing Attribute: If it's there, will be removed. If it's missing, will be added.
    ///
    /// - Parameter trait: The Font Property that should be toggled.
    ///
    private func updateTypingAttribute(toggle attributeName: String, value: AnyObject) {
        if typingAttributes[attributeName] != nil {
            typingAttributes.removeValue(forKey: attributeName)
            return
        }

        typingAttributes[attributeName] = value
    }


    // MARK: - Selection Markers

    fileprivate enum SelectionMarker: String {
        case start = "SelectionStart"
        case end = "SelectionEnd"
    }

    fileprivate func markCurrentSelection() {
        let range = selectedRange
        // selection marking
        if range.location + 1 < storage.length {
            storage.addAttribute(SelectionMarker.start.rawValue, value: SelectionMarker.start.rawValue, range: NSRange(location:range.location, length: 1))
        }
        if range.endLocation + 1 < storage.length {
            storage.addAttribute(SelectionMarker.end.rawValue, value: SelectionMarker.end.rawValue, range: NSRange(location:range.location + range.length, length: 1))
        }
    }

    fileprivate func restoreMarkedSelection() {
        var selectionStartRange: NSRange = NSRange(location: max(storage.length, 0), length: 0)
        var selectionEndRange: NSRange = selectionStartRange
        storage.enumerateAttribute(SelectionMarker.start.rawValue,
                                   in: NSRange(location: 0, length: storage.length),
                                   options: []) { (attribute, range, stop) in
                                    if attribute != nil {
                                        selectionStartRange = range
                                    }
        }

        storage.enumerateAttribute(SelectionMarker.end.rawValue,
                                   in: NSRange(location: 0, length: storage.length),
                                   options: []) { (attribute, range, stop) in
                                    if attribute != nil {
                                        selectionEndRange = range
                                    }
        }

        storage.removeAttribute(SelectionMarker.start.rawValue, range: selectionStartRange)
        storage.removeAttribute(SelectionMarker.end.rawValue, range: selectionEndRange)
        selectedRange = NSRange(location:selectionStartRange.location, length: selectionEndRange.location - selectionStartRange.location)
        self.delegate?.textViewDidChangeSelection?(self)
    }

    // MARK: - Lists

    /// Refresh Lists attributes when insert new text in the specified range
    ///
    /// - Parameters:
    ///   - text: the text being added
    ///   - range: the range of the insertion of the new text
    private func refreshListAfterInsertionOf(text:String, range:NSRange) {
        //check if new text is part of a list
        guard let textList = storage.textListAttribute(atIndex: range.location) else {
            return
        }

        let afterRange = NSRange(location: range.location + 1, length: 1)
        let beforeRange = NSRange(location: range.location - 1, length: 1)

        var afterString = "\n"
        var beforeString = "\n"
        if beforeRange.location >= 0 {
            beforeString = storage.attributedSubstring(from: beforeRange).string
        }
        if afterRange.endLocation < storage.length {
            afterString = storage.attributedSubstring(from: afterRange).string
        }

        let isBegginingOfListItem = storage.isStartOfNewLine(atLocation: range.location)

        if text == "\n" && beforeString == "\n" && afterString == "\n" && isBegginingOfListItem {
            remove(list:textList, at: range)
            if afterRange.endLocation < storage.length {
                remove(list: textList, at: afterRange)
                deleteBackward()
            } else {
                selectedRange = NSRange(location: range.location, length: 0)
            }
        }
    }

    /// Refresh Lists attributes when text is deleted in the specified range
    ///
    /// - Parameters:
    ///   - text: the text being added
    ///   - range: the range of the insertion of the new text
    private func refreshListAfterDeletionOf(text deletedText: NSAttributedString, atRange range:NSRange) {
        guard let textList = deletedText.textListAttribute(atIndex: 0),
              deletedText.string == "\n" || range.location == 0 else {
            return
        }

        if (range.location == 0) {
            remove(list: textList, at: range)
        }
    }

    fileprivate func remove(list: TextList, at range: NSRange) {
        let formatter = TextListFormatter(style: list.style)
        formatter.toggleAttribute(inTextView: self, atRange: range)
    }

    /// Adds or removes a ordered list style from the specified range.
    ///
    /// - Parameter range: The NSRange to edit.
    ///
    open func toggleOrderedList(range: NSRange) {
        let formatter = TextListFormatter(style: .ordered)
        formatter.toggleAttribute(inTextView: self, atRange: range)
    }


    /// Adds or removes a unordered list style from the specified range.
    ///
    /// - Parameter range: The NSRange to edit.
    ///
    open func toggleUnorderedList(range: NSRange) {
        let formatter = TextListFormatter(style: .unordered)
        formatter.toggleAttribute(inTextView: self, atRange: range)
    }

    // MARK: - Blockquotes

    /// Adds or removes a blockquote style from the specified range.
    /// Blockquotes are applied to an entire paragrah regardless of the range.
    /// If the range spans multiple paragraphs, the style is applied to all
    /// affected paragraphs.
    ///
    /// - Parameters:
    ///     - range: The NSRange to edit.
    ///
    open func toggleBlockquote(range: NSRange) {
        let formatter = BlockquoteFormatter()
        formatter.toggleAttribute(inTextView: self, atRange: range)
    }

    /// Refresh Lists attributes when text is deleted in the specified range
    ///
    /// - Parameters:
    ///   - text: the text being added
    ///   - range: the range of the insertion of the new text
    ///
    private func refreshBlockquoteAfterDeletionOf(text deletedText: NSAttributedString, atRange range:NSRange) {
        let formatter = BlockquoteFormatter()
        guard formatter.attribute(inTextView: self, at: range.location),
            deletedText.string == "\n" || range.location == 0 else {
                return
        }

        if (range.location == 0) {
            formatter.toggleAttribute(inTextView: self, atRange: range)
        }
    }

    /// Refresh blockquotes attributes when inserting new text in the specified range
    ///
    /// - Parameters:
    ///   - text: the text being added
    ///   - range: the range of the insertion of the new text
    ///
    private func refreshBlockquoteAfterInsertionOf(text: String, range:NSRange) {
        let formatter = BlockquoteFormatter()
        guard formatter.attribute(inTextView: self, at: range.location) else {
            return
        }

        let afterRange = NSRange(location: range.location + 1, length: 1)
        let beforeRange = NSRange(location: range.location - 1, length: 1)

        var afterString = "\n"
        var beforeString = "\n"
        if beforeRange.location >= 0 {
            beforeString = storage.attributedSubstring(from: beforeRange).string
        }
        if afterRange.endLocation < storage.length {
            afterString = storage.attributedSubstring(from: afterRange).string
        }

        let isBegginingOfListItem = storage.isStartOfNewLine(atLocation: range.location)

        if text == "\n" && beforeString == "\n" && afterString == "\n" && isBegginingOfListItem {
            formatter.toggleAttribute(inTextView: self, atRange: range)
            if afterRange.endLocation < storage.length {
                formatter.toggleAttribute(inTextView: self, atRange: afterRange)
                deleteBackward()
            } else {
                selectedRange = NSRange(location: range.location, length: 0)
            }
        }
    }


    // MARK: - Links

    /// Adds a link to the designated url on the specified range.
    ///
    /// - Parameters:
    ///     - url: the NSURL to link to.
    ///     - title: the text for the link.
    ///     - range: The NSRange to edit.
    ///
    open func setLink(_ url: URL, title: String, inRange range: NSRange) {
        let index = range.location
        let length = title.characters.count
        let insertionRange = NSMakeRange(index, length)
        storage.replaceCharacters(in: range, with: title)
        storage.setLink(url, forRange: insertionRange)
    }

    open func removeLink(inRange range:NSRange) {
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
    /// - Returns: an id of the attachment that can be used for further calls
    open func insertImage(sourceURL url: URL, atPosition position: Int, placeHolderImage: UIImage?) -> String {
        let imageId = storage.insertImage(sourceURL: url, atPosition: position, placeHolderImage: placeHolderImage ?? defaultMissingImage)
        let length = NSAttributedString(attachment:NSTextAttachment()).length
        selectedRange = NSMakeRange(position+length, 0)
        return imageId
    }

    open func attachment(withId id: String) -> TextAttachment? {
        return storage.attachment(withId: id);
    }
    /// Inserts a Video attachment at the specified index
    ///
    /// - Parameters:
    ///     - index: The character index at which to insert the image.
    ///     - params: TBD
    ///
    open func insertVideo(_ index: Int, params: [String: AnyObject]) {
        print("video")
    }


    // MARK: - Inspectors
    // MARK: - Inspect Within Range


    /// Returns the associated TextAttachment, at a given point, if any.
    ///
    /// - Parameter point: The point on screen to check for attachments.
    ///
    /// - Returns: The associated TextAttachment.
    ///
    open func attachmentAtPoint(_ point: CGPoint) -> TextAttachment? {
        let index = layoutManager.characterIndex(for: point, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        guard index <= textStorage.length else {
            return nil
        }

        return textStorage.attribute(NSAttachmentAttributeName, at: index, effectiveRange: nil) as? TextAttachment
    }


    /// Check if the bold attribute spans the specified range.
    ///
    /// - Parameter range: The NSRange to inspect.
    ///
    /// - Returns: True if the attribute spans the entire range.
    ///
    open func boldFormattingSpansRange(_ range: NSRange) -> Bool {
        return storage.fontTrait(.traitBold, spansRange: range)
    }


    /// Check if the italic attribute spans the specified range.
    ///
    /// - Parameter range: The NSRange to inspect.
    ///
    /// - Returns: True if the attribute spans the entire range.
    ///
    open func italicFormattingSpansRange(_ range: NSRange) -> Bool {
        return storage.fontTrait(.traitItalic, spansRange: range)
    }


    /// Check if the underline attribute spans the specified range.
    ///
    /// - Parameter range: The NSRange to inspect.
    ///
    /// - Returns: True if the attribute spans the entire range.
    ///
    open func underlineFormattingSpansRange(_ range: NSRange) -> Bool {
        let index = maxIndex(range.location)
        var effectiveRange = NSRange()
        guard let attribute = storage.attribute(NSUnderlineStyleAttributeName, at: index, effectiveRange: &effectiveRange) as? Int else {
            return false
        }

        return attribute == NSUnderlineStyle.styleSingle.rawValue && NSEqualRanges(range, NSIntersectionRange(range, effectiveRange))
    }


    /// Check if the strikethrough attribute spans the specified range.
    ///
    /// - Parameter range: The NSRange to inspect.
    ///
    /// - Returns: True if the attribute spans the entire range.
    ///
    open func strikethroughFormattingSpansRange(_ range: NSRange) -> Bool {
        let index = maxIndex(range.location)
        var effectiveRange = NSRange()
        guard let attribute = storage.attribute(NSStrikethroughStyleAttributeName, at: index, effectiveRange: &effectiveRange) as? Int else {
            return false
        }

        return attribute == NSUnderlineStyle.styleSingle.rawValue && NSEqualRanges(range, NSIntersectionRange(range, effectiveRange))
    }

    /// Check if the link attribute spans the specified range.
    ///
    /// - Parameter range: The NSRange to inspect.
    ///
    /// - Returns: True if the attribute spans the entire range.
    ///
    open func linkFormattingSpansRange(_ range: NSRange) -> Bool {
        let index = maxIndex(range.location)
        var effectiveRange = NSRange()
        if storage.attribute(NSLinkAttributeName, at: index, effectiveRange: &effectiveRange) != nil {

           return NSEqualRanges(range, NSIntersectionRange(range, effectiveRange))
        }
        return false
    }


    /// Check if an ordered list spans the specified range.
    ///
    /// - Parameter range: The NSRange to inspect.
    ///
    /// - Returns: True if the attribute spans the entire range.
    ///
    open func orderedListFormattingSpansRange(_ range: NSRange) -> Bool {
        return storage.textListAttribute(spanningRange: range)?.style == .ordered
    }


    /// Check if an unordered list spans the specified range.
    ///
    /// - Parameter range: The NSRange to inspect.
    ///
    /// - Returns: True if the attribute spans the entire range.
    ///
    open func unorderedListFormattingSpansRange(_ range: NSRange) -> Bool {
        return storage.textListAttribute(spanningRange: range)?.style == .unordered
    }


    /// Returns an NSURL if the specified range as attached a link attribute
    ///
    /// - Parameter range: The NSRange to inspect
    ///
    /// - returns: the NSURL if available
    ///
    open func linkURL(forRange range: NSRange) -> URL? {
        let index = maxIndex(range.location)
        var effectiveRange = NSRange()
        if let attr = storage.attribute(NSLinkAttributeName, at: index, effectiveRange: &effectiveRange) {
            if let url = attr as? URL {
                return url
            } else if let urlString = attr as? String {
                return URL(string:urlString)
            }
        }
        return nil
    }

    open func linkFullRange(forRange range: NSRange) -> NSRange? {
        let index = maxIndex(range.location)
        var effectiveRange = NSRange()
        if storage.attribute(NSLinkAttributeName, at: index, effectiveRange: &effectiveRange) != nil {
            return effectiveRange
        }
        return nil
    }

    /// Check if the blockquote attribute spans the specified range.
    ///
    /// - Parameter range: The NSRange to inspect.
    ///
    /// - Returns: True if the attribute spans the entire range.
    ///
    open func blockquoteFormattingSpansRange(_ range: NSRange) -> Bool {
        let index = maxIndex(range.location)
        var effectiveRange = NSRange()
        guard let attribute = storage.attribute(NSParagraphStyleAttributeName, at: index, effectiveRange: &effectiveRange) as? NSParagraphStyle else {
            return false
        }

        return attribute.headIndent == Metrics.defaultIndentation && NSEqualRanges(range, NSIntersectionRange(range, effectiveRange))
    }


    /// The maximum index should never exceed the length of the text storage minus one,
    /// else we court out of index exceptions.
    ///
    /// - Parameter index: The candidate index. If the index is greater than the max allowed, the max is returned.
    ///
    /// - Returns: If the index is greater than the max allowed, the max is returned, else the original value.
    ///
    func maxIndex(_ index: Int) -> Int {
        if index >= storage.length {
            return storage.length - 1
        }
        return index
    }


    /// In most instances, the value of NSRange.location is off by one when compared to a character index.
    /// Call this method to get an adjusted character index from an NSRange.location.
    ///
    /// - Parameter index: The candidate index.
    ///
    /// - Returns: The specified or maximum index.
    ///
    func adjustedIndex(_ index: Int) -> Int {
        let index = maxIndex(index)
        return max(0, index - 1)
    }


    /// TextListFormatter was designed to be applied over a range of text. Whenever such range is
    /// zero, we may have trouble determining where to apply the list. For that reason,
    /// whenever the list range's length is zero, we'll attempt to infer the range of the line at
    /// which the cursor is located.
    ///
    /// - Parameter range: The NSRange in which a TextList should be applied
    ///
    /// Returns: A corrected NSRange, if the original one had empty length.
    ///
    func rangeForTextList(_ range: NSRange) -> NSRange {
        guard range.length == 0 else {
            return range
        }

        return storage.rangeOfLine(atIndex: range.location) ?? range
    }


    /// Returns the expected Selected Range for a given TextList, with the specified Effective Range,
    /// and the Applied Range.
    ///
    /// Note that "Effective Range" is the actual List Range (including Markers), whereas Applied Range is just
    /// the range at which the list was originally inserted.
    ///
    /// - Parameters:
    ///     - effectiveRange: The actual range occupied by the List. Includes the String Markers!
    ///     - appliedRange: The (original) range at which the list was applied.
    ///
    /// - Returns: If the current selection's length is zero, we'll return the selectedRange with it's location
    ///   updated to consider the left padding applied by the list. Otherwise, we'll return the List's 
    ///   Effective range.
    ///
    func rangeForSelectedTextList(withEffectiveRange effectiveRange: NSRange, andAppliedRange appliedRange: NSRange) -> NSRange {
        guard selectedRange.length == 0 else {
            return effectiveRange
        }

        var newSelectedRange = selectedRange
        newSelectedRange.location += effectiveRange.length - appliedRange.length

        return newSelectedRange
    }


    // MARK - Inspect at Index


    /// Check if the bold attribute exists at the specified index.
    ///
    /// - Parameter index: The character index to inspect.
    ///
    /// - Returns: True if the attribute exists at the specified index.
    ///
    open func formattingAtIndexContainsBold(_ index: Int) -> Bool {
        return storage.fontTrait(.traitBold, existsAtIndex: index)
    }


    /// Check if the italic attribute exists at the specified index.
    ///
    /// - Parameter index: The character index to inspect.
    ///
    /// - Returns: True if the attribute exists at the specified index.
    ///
    open func formattingAtIndexContainsItalic(_ index: Int) -> Bool {
        return storage.fontTrait(.traitItalic, existsAtIndex: index)
    }


    /// Check if the underline attribute exists at the specified index.
    ///
    /// - Parameter index: The character index to inspect.
    ///
    /// - Returns: True if the attribute exists at the specified index.
    ///
    open func formattingAtIndexContainsUnderline(_ index: Int) -> Bool {
        guard let attribute = storage.attribute(NSUnderlineStyleAttributeName, at: index, effectiveRange: nil) as? Int else {
            return false
        }
        // TODO: Figure out how to reconcile this with Link style.
        return attribute == NSUnderlineStyle.styleSingle.rawValue
    }


    /// Check if the strikethrough attribute exists at the specified index.
    ///
    /// - Parameter index: The character index to inspect.
    ///
    /// - Returns: True if the attribute exists at the specified index.
    ///
    open func formattingAtIndexContainsStrikethrough(_ index: Int) -> Bool {
        guard let attribute = storage.attribute(NSStrikethroughStyleAttributeName, at: index, effectiveRange: nil) as? Int else {
            return false
        }

        return attribute == NSUnderlineStyle.styleSingle.rawValue
    }

    /// Check if the link attribute exists at the specified index.
    ///
    /// - Parameter index: The character index to inspect.
    ///
    /// - Returns: True if the attribute exists at the specified index.
    ///
    open func formattingAtIndexContainsLink(_ index: Int) -> Bool {
        guard storage.attribute(NSLinkAttributeName, at: index, effectiveRange: nil) != nil else {
            return false
        }

        return true
    }

    
    /// Check if the blockquote attribute exists at the specified index.
    ///
    /// - Parameter index: The character index to inspect.
    ///
    /// - Returns: True if the attribute exists at the specified index.
    ///
    open func formattingAtIndexContainsBlockquote(_ index: Int) -> Bool {
        let formatter = BlockquoteFormatter()
        return formatter.attribute(inTextView: self, at: index)
    }


    /// Check if an ordered list exists at the specified index.
    ///
    /// - Paramters:
    ///     - index: The character index to inspect.
    ///
    /// - Returns: True if the attribute exists at the specified index.
    ///
    open func formattingAtIndexContainsOrderedList(_ index: Int) -> Bool {
        return storage.textListAttribute(atIndex: index)?.style == .ordered
    }


    /// Check if an unordered list exists at the specified index.
    ///
    /// - Paramters:
    ///     - index: The character index to inspect.
    ///
    /// - Returns: True if the attribute exists at the specified index.
    ///
    open func formattingAtIndexContainsUnorderedList(_ index: Int) -> Bool {
        return storage.textListAttribute(atIndex: index)?.style == .unordered
    }


    // MARK: - Inspect Typing Attributes


    /// Checks if the next character entered by the user will be in Bold, or not.
    ///
    open func typingAttributesContainsBold() -> Bool {
        guard let font = typingAttributes[NSFontAttributeName] as? UIFont else {
            return false
        }

        return font.containsTraits(.traitBold)
    }


    /// Checks if the next character entered by the user will be in Italic, or not.
    ///
    open func typingAttributesContainsItalic() -> Bool {
        guard let font = typingAttributes[NSFontAttributeName] as? UIFont else {
            return false
        }

        return font.containsTraits(.traitItalic)
    }


    /// Checks if the next character that the user types will get Strikethrough Attribute, or not.
    ///
    open func typingAttributesContainsStrikethrough() -> Bool {
        return typingAttributes[NSStrikethroughStyleAttributeName] != nil
    }


    /// Checks if the next character that the user types will be underlined, or not.
    ///
    open func typingAttributesContainsUnderline() -> Bool {
        return typingAttributes[NSUnderlineStyleAttributeName] != nil
    }


    /// Checks if the next character that the user types will be formatted as Blockquote, or not.
    ///
    open func typingAttributesContainsBlockquote() -> Bool {
        let paragraphStyle = typingAttributes[NSParagraphStyleAttributeName] as? ParagraphStyle
        return paragraphStyle?.blockquote != nil
    }


    /// Checks if the next character that the user types will be formatted as an Ordered List, or not.
    ///
    open func typingAttributesContainsOrderedList() -> Bool {
        let paragraphStyle = typingAttributes[NSParagraphStyleAttributeName] as? ParagraphStyle
        return paragraphStyle?.textList?.style == .ordered
    }


    /// Checks if the next character that the user types will be formatted as an Unordered List, or not.
    ///
    open func typingAttributesContainsUnorderedList() -> Bool {
        let paragraphStyle = typingAttributes[NSParagraphStyleAttributeName] as? ParagraphStyle
        return paragraphStyle?.textList?.style == .unordered
    }

    /// Checks if the next character that the user types will be part of a link anchor, or not.
    ///
    open func typingAttributesContainsLink() -> Bool {
        return typingAttributes[NSLinkAttributeName] != nil
    }


    // MARK: - Attachments

    /// Updates the attachment properties to the new values
    ///
    /// - parameter attachment: the attachment to update
    /// - parameter alignment:  the alignment value
    /// - parameter size:       the size value
    /// - parameter url:        the attachment url
    ///
    open func update(attachment: TextAttachment,
                                  alignment: TextAttachment.Alignment,
                                  size: TextAttachment.Size,
                                  url: URL) {
        storage.update(attachment: attachment, alignment: alignment, size: size, url: url)
        layoutManager.invalidateLayoutForAttachment(attachment)
    }

    /// Update the progress indicator of an attachment
    ///
    /// - Parameters:
    ///   - attachment: the attachment to update
    ///   - progress: the value of progress
    ///
    open func update(attachment: TextAttachment, progress: Double?, progressColor: UIColor = UIColor.blue) {
        attachment.progress = progress
        attachment.progressColor = progressColor
        layoutManager.invalidateLayoutForAttachment(attachment)
    }

    /// Updates the message being displayed on top of the image attachment
    ///
    /// - Parameters:
    ///   - attachment: the attachment where the message will be overlay
    ///   - message: the message to show
    ///
    open func update(attachment: TextAttachment, message: NSAttributedString?) {
        attachment.message = message
        layoutManager.invalidateLayoutForAttachment(attachment)
    }
}

// MARK: - TextStorageImageProvider

extension TextView: TextStorageAttachmentsDelegate {

    func storage(
        _ storage: TextStorage,
        attachment: TextAttachment,
        imageForURL url: URL,
        onSuccess success: @escaping (UIImage) -> (),
        onFailure failure: @escaping () -> ()) -> UIImage {
        
        guard let mediaDelegate = mediaDelegate else {
            fatalError("This class requires a media delegate to be set.")
        }
        
        let placeholderImage = mediaDelegate.textView(self, imageAtUrl: url, onSuccess: success, onFailure: failure)
        return placeholderImage
    }

    func storage(_ storage: TextStorage, missingImageForAttachment: TextAttachment) -> UIImage {
        return defaultMissingImage
    }
    
    func storage(_ storage: TextStorage, urlForImage image: UIImage) -> URL {
        
        guard let mediaDelegate = mediaDelegate else {
            fatalError("This class requires a media delegate to be set.")
        }
        
        return mediaDelegate.textView(self, urlForImage: image)
    }
}
