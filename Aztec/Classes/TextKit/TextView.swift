
import UIKit
import Foundation
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

    /// Called when an attachment is about to be added to the storage as an attachment (copy/paste), so that the
    /// delegate can specify an URL where that attachment is available.
    ///
    /// - Parameters:
    ///     - textView: The textView that is requesting the image.
    ///     - attachment: The attachment that was added to the storage.
    ///
    /// - Returns: the requested `NSURL` where the image is stored.
    ///
    func textView(
        _ textView: TextView,
        urlForAttachment attachment: TextAttachment) -> URL


    /// Called when a attachment is removed from the storage.
    ///
    /// - Parameters:
    ///   - textView: The textView where the attachment was removed.
    ///   - attachmentID: The attachment identifier of the media removed.
    func textView(_ textView: TextView, deletedAttachmentWithID attachmentID: String);
}

public protocol TextViewFormattingDelegate: class {

    /// Called a text view command toggled a style.
    ///
    /// If you have a format bar, you should probably update it here.
    ///
    func textViewCommandToggledAStyle()
}

open class TextView: UITextView {

    typealias ElementNode = Libxml2.ElementNode


    // MARK: - Properties: Attachments & Media

    /// The media delegate takes care of providing remote media when requested by the `TextView`.
    /// If this is not set, all remove images will be left blank.
    ///
    open weak var mediaDelegate: TextViewMediaDelegate?

    // MARK: - Properties: Formatting

    open weak var formattingDelegate: TextViewFormattingDelegate?

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
        guard let string = UIPasteboard.general.loadAttributedString() else {
            super.paste(sender)
            return
        }

        string.loadLazyAttachments()

        storage.replaceCharacters(in: selectedRange, with: string)
        selectedRange = NSRange(location: selectedRange.location + string.length, length: 0)
    }

    open func pasteAndMatchStyle(_ sender: Any?) {
        guard let string = UIPasteboard.general.loadAttributedString()?.mutableCopy() as? NSMutableAttributedString else {
            super.paste(sender)
            return
        }


        let range = string.rangeOfEntireString
        string.addAttributes(typingAttributes, range: range)
        string.loadLazyAttachments()

        storage.replaceCharacters(in: selectedRange, with: string)
        selectedRange = NSRange(location: selectedRange.location + string.length, length: 0)
    }


    // MARK: - Intersect keyboard operations

    open override func insertText(_ text: String) {
        // Note:
        // Whenever the entered text causes the Paragraph Attributes to be removed, we should prevent the actual
        // text insertion to happen. Thus, we won't call super.insertText.
        // But because we don't call the super we need to refresh the attributes ourselfs, and callback to the delegate.
        if ensureRemovalOfParagraphAttributes(insertedText: text, at: selectedRange) {
            if (self.textStorage.length > 0) {
                typingAttributes = textStorage.attributes(at: min(selectedRange.location, textStorage.length-1), effectiveRange: nil)
            }
            delegate?.textViewDidChangeSelection?(self)
            delegate?.textViewDidChange?(self)
            return
        }

        super.insertText(text)

        ensureRemovalOfSingleLineParagraphAttributes(insertedText: text, at: selectedRange)

        ensureCursorRedraw(afterEditing: text)
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

        refreshListAfterDeletion(of: deletedString, at: deletionRange)
        refreshBlockquoteAfterDeletion(of: deletedString, at: deletionRange)
        refreshHeaderAfterDeletion(of: deletedString, at: deletionRange)
        ensureCursorRedraw(afterEditing: deletedString.string)
        delegate?.textViewDidChange?(self)
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
        if storage.length > 0 && selectedRange.location < storage.length {
            typingAttributes = storage.attributes(at: selectedRange.location, effectiveRange: nil)
        }
        delegate?.textViewDidChange?(self)
        formattingDelegate?.textViewCommandToggledAStyle()
    }


    // MARK: - Getting format identifiers

    private let formatterIdentifiersMap: [FormattingIdentifier: AttributeFormatter] = [
        .bold: BoldFormatter(),
        .italic: ItalicFormatter(),
        .underline: UnderlineFormatter(),
        .strikethrough: StrikethroughFormatter(),
        .link: LinkFormatter(),
        .orderedlist: TextListFormatter(style: .ordered),
        .unorderedlist: TextListFormatter(style: .unordered),
        .blockquote: BlockquoteFormatter(),
        .header: HeaderFormatter(),
    ]

    /// Get a list of format identifiers spanning the specified range as a String array.
    ///
    /// - Parameter range: An NSRange to inspect.
    ///
    /// - Returns: A list of identifiers.
    ///
    open func formatIdentifiersSpanningRange(_ range: NSRange) -> [FormattingIdentifier] {
        guard storage.length != 0 else {
            return formatIdentifiersForTypingAttributes()
        }

        if range.length == 0 {
            return formatIdentifiersAtIndex(range.location)
        }

        var identifiers = [FormattingIdentifier]()

        for (key, formatter) in formatterIdentifiersMap {
            if formatter.present(in: storage, at: range) {
                identifiers.append(key)
            }
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

        for (key, formatter) in formatterIdentifiersMap {
            if formatter.present(in: storage, at: index) {
                identifiers.append(key)
            }
        }

        return identifiers
    }


    /// Get a list of format identifiers of the Typing Attributes.
    ///
    /// - Returns: A list of Formatting Identifiers.
    ///
    open func formatIdentifiersForTypingAttributes() -> [FormattingIdentifier] {
        var identifiers = [FormattingIdentifier]()

        for (key, formatter) in formatterIdentifiersMap {
            if formatter.present(in: typingAttributes) {
                identifiers.append(key)
            }
        }

        return identifiers
    }

    // MARK: - UIResponderStandardEditActions

    open override func toggleBoldface(_ sender: Any?) {
        super.toggleBoldface(sender)
        formattingDelegate?.textViewCommandToggledAStyle()
    }

    open override func toggleItalics(_ sender: Any?) {
        super.toggleItalics(sender)
        formattingDelegate?.textViewCommandToggledAStyle()
    }

    open override func toggleUnderline(_ sender: Any?) {
        super.toggleUnderline(sender)
        formattingDelegate?.textViewCommandToggledAStyle()
    }

    // MARK: - Formatting

    func toggle(formatter: AttributeFormatter, atRange range: NSRange) {
        let newSelectedRange = storage.toggle(formatter: formatter, at: range)         
        selectedRange = newSelectedRange ?? selectedRange
        if selectedRange.length == 0 {
            typingAttributes = formatter.toggle(in: typingAttributes)
        } else {
            // NOTE: We are making sure that the selectedRange location is inside the string
            // The selected range can be out of the string when you are adding content to the end of the string.
            // In those cases we check the atributes of the previous caracter
            let location = max(0,min(selectedRange.location, textStorage.length-1))
            typingAttributes = textStorage.attributes(at: location, effectiveRange: nil)
        }
        delegate?.textViewDidChange?(self)
    }

    /// Adds or removes a bold style from the specified range.
    ///
    /// - Parameter range: The NSRange to edit.
    ///
    open func toggleBold(range: NSRange) {
        let formatter = BoldFormatter()
        toggle(formatter: formatter, atRange: range)
    }


    /// Adds or removes a italic style from the specified range.
    ///
    /// - Parameter range: The NSRange to edit.
    ///
    open func toggleItalic(range: NSRange) {
        let formatter = ItalicFormatter()
        toggle(formatter: formatter, atRange: range)
    }


    /// Adds or removes a underline style from the specified range.
    ///
    /// - Parameter range: The NSRange to edit.
    ///
    open func toggleUnderline(range: NSRange) {
        let formatter = UnderlineFormatter()
        toggle(formatter: formatter, atRange: range)
    }


    /// Adds or removes a strikethrough style from the specified range.
    ///
    /// - Parameter range: The NSRange to edit.
    ///
    open func toggleStrikethrough(range: NSRange) {
        let formatter = StrikethroughFormatter()
        toggle(formatter: formatter, atRange: range)
    }

    /// Adds or removes a blockquote style from the specified range.
    /// Blockquotes are applied to an entire paragrah regardless of the range.
    /// If the range spans multiple paragraphs, the style is applied to all
    /// affected paragraphs.
    ///
    /// - Parameters:
    ///     - range: The NSRange to edit.
    ///
    open func toggleBlockquote(range: NSRange) {
        let formatter = BlockquoteFormatter(placeholderAttributes: typingAttributes)
        toggle(formatter: formatter, atRange: range)
        forceRedrawCursorAfterDelay()
    }

    /// Adds or removes a ordered list style from the specified range.
    ///
    /// - Parameter range: The NSRange to edit.
    ///
    open func toggleOrderedList(range: NSRange) {
        let formatter = TextListFormatter(style: .ordered, placeholderAttributes: typingAttributes)
        toggle(formatter: formatter, atRange: range)
        forceRedrawCursorAfterDelay()
    }


    /// Adds or removes a unordered list style from the specified range.
    ///
    /// - Parameter range: The NSRange to edit.
    ///
    open func toggleUnorderedList(range: NSRange) {
        let formatter = TextListFormatter(style: .unordered, placeholderAttributes: typingAttributes)
        toggle(formatter: formatter, atRange: range)
        forceRedrawCursorAfterDelay()
    }

    /// Adds or removes a unordered list style from the specified range.
    ///
    /// - Parameter range: The NSRange to edit.
    ///
    open func toggleHeader(range: NSRange) {
        let formatter = HeaderFormatter(placeholderAttributes: typingAttributes)
        toggle(formatter: formatter, atRange: range)
        forceRedrawCursorAfterDelay()
    }

    // MARK: - Lists

    /// Refresh Lists attributes when text is deleted in the specified range
    ///
    /// - Parameters:
    ///   - text: the text being added
    ///   - range: the range of the insertion of the new text
    ///
    private func refreshListAfterDeletion(of deletedText: NSAttributedString, at range: NSRange) {
        guard let textList = deletedText.textListAttribute(atIndex: 0),
              deletedText.string == String(.newline) && range.location == 0 else {
            return
        }

        // Proceed to remove the list
        // TODO: We should have explicit methods to Remove a TextList format, rather than just calling Toggle
        //
        switch textList.style {
        case .ordered:
            toggleOrderedList(range: range)
        case .unordered:
            toggleUnorderedList(range: range)
        }
    }

    // MARK: - Blockquotes

    /// Refresh Blockquote attributes when text is deleted at the specified range.
    ///
    /// - Notes: Toggles the Blockquote Style, whenever the deleted text is at the beginning of the text.
    ///
    /// - Parameters:
    ///   - text: the text being deleted
    ///   - range: the deletion range
    ///
    private func refreshBlockquoteAfterDeletion(of text: NSAttributedString, at range: NSRange) {
        let formatter = BlockquoteFormatter(placeholderAttributes: typingAttributes)
        guard formatter.present(in: textStorage, at: range.location), range.location == 0 else {
            return
        }

        // Remove the Blockquote.
        // TODO: We should have explicit methods to Remove a Blockquote format, rather than just calling Toggle
        //
        toggleBlockquote(range: range)
    }

    // MARK: - Blockquotes

    /// Refresh Header attributes when text is deleted at the specified range.
    ///
    /// - Notes: Toggles the Header Style, whenever the deleted text is at the beginning of the text.
    ///
    /// - Parameters:
    ///   - text: the text being deleted
    ///   - range: the deletion range
    ///
    private func refreshHeaderAfterDeletion(of deletedText: NSAttributedString, at range: NSRange) {
        let formatter = HeaderFormatter(placeholderAttributes: typingAttributes)
        guard formatter.present(in: textStorage, at: range.location),
            deletedText.string == String(.newline) else {
                return
        }

        // Proceed to remove the header
        // TODO: We should have explicit methods to apply a Header format, rather than just calling Toggle
        // the double call it's because the first call will actually remove the header and we want to add it to all the new line
        toggleHeader(range: range)
        toggleHeader(range: range)
    }


    /// Indicates whether ParagraphStyles should be removed, when inserting the specified string, at a given location,
    /// or not. Note that we should remove Paragraph Styles whenever:
    ///
    /// -   The previous string contains just a newline
    /// -   The next string is a newline (or we're at the end of the text storage)
    /// -   We're at the beginning of a new line
    /// -   The user just typed a new line
    ///
    /// - Parameters:
    ///     - insertedText: String that was just inserted
    ///     - at: Location in which the string was just inserted
    ///
    /// - Returns: True if we should remove the paragraph attributes. False otherwise!
    ///
    private func shouldRemoveParagraphAttributes(insertedText text: String, at location: Int) -> Bool {
        guard text == String(.newline) else {
            return false
        }

        let afterRange = NSRange(location: location, length: 1)
        let beforeRange = NSRange(location: location - 1, length: 1)

        var afterString = String(.newline)
        var beforeString = String(.newline)
        if beforeRange.location >= 0 {
            beforeString = storage.attributedSubstring(from: beforeRange).string
        }

        if afterRange.endLocation < storage.length {
            afterString = storage.attributedSubstring(from: afterRange).string
        }

        return beforeString == String(.newline) && afterString == String(.newline) && storage.isStartOfNewLine(atLocation: location)
    }

    /// This helper will proceed to remove the Paragraph attributes, in a given string, at the specified range,
    /// if needed (please, check `shouldRemoveParagraphAttributes` to learn the conditions that would trigger this!).
    ///
    /// - Parameters:
    ///     - insertedText: String that just got inserted.
    ///     - at: Range in which the string was inserted.
    ///
    /// - Returns: True if ParagraphAttributes were removed. False otherwise!
    ///
    func ensureRemovalOfParagraphAttributes(insertedText text: String, at range: NSRange) -> Bool {

        guard shouldRemoveParagraphAttributes(insertedText: text, at: range.location) else {
            return false
        }

        let identifiers = formatIdentifiersAtIndex(range.location)

        if identifiers.contains(.orderedlist) {
            toggleOrderedList(range: range)
            return true
        }

        if identifiers.contains(.unorderedlist) {
            toggleUnorderedList(range: range)
            return true
        }

        if identifiers.contains(.blockquote) {
            toggleBlockquote(range: range)
            return true
        }
        
        return false
    }

    /// Indicates whether a new empty paragraph was created after the insertion of text at the specified location
    ///
    /// - Parameters:
    ///     - insertedText: String that was just inserted
    ///     - at: Location in which the string was just inserted
    ///
    /// - Returns: True if we should remove the paragraph attributes. False otherwise!
    ///
    private func isNewEmptyParagraphAfter(insertedText text: String, at location: Int) -> Bool {
        guard text == String(.newline) else {
            return false
        }

        let afterRange = NSRange(location: location, length: 1)
        var afterString = String(.newline)

        if afterRange.endLocation < storage.length {
            afterString = storage.attributedSubstring(from: afterRange).string
        }

        return afterString == String(.newline) && storage.isStartOfNewLine(atLocation: location)
    }

    /// This helper will proceed to remove the Paragraph attributes when a new line is inserted at the end of an paragraph.
    /// Examples of this are the header attributes (Heading 1 to 6) When you start a new paragraph it shoudl reset to the standard style.
    ///
    /// - Parameters:
    ///     - insertedText: String that just got inserted.
    ///     - at: Range in which the string was inserted.
    ///
    /// - Returns: True if ParagraphAttributes were removed. False otherwise!
    ///
    @discardableResult func ensureRemovalOfSingleLineParagraphAttributes(insertedText text: String, at range: NSRange) -> Bool {

        guard isNewEmptyParagraphAfter(insertedText: text, at: range.location) else {
            return false
        }

        let identifiers = formatIdentifiersAtIndex(range.location)

        if identifiers.contains(.header) {
            toggleHeader(range: range)
            return true
        }

        return false
    }

    /// Force the SDK to Redraw the cursor, asynchronously, if the edited text (inserted / deleted) requires it.
    /// This method was meant as a workaround for Issue #144.
    ///
    func ensureCursorRedraw(afterEditing text: String) {
        guard text == String(.newline) else {
            return
        }

        forceRedrawCursorAfterDelay()
    }


    /// Force the SDK to Redraw the cursor, asynchronously, after a delay. This method was meant as a workaround
    /// for Issue #144: the Caret might end up redrawn below the Blockquote's custom background.
    ///
    func forceRedrawCursorAfterDelay() {
        let delay = 0.05
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            let pristine = self.selectedRange
            let updated = NSMakeRange(max(pristine.location - 1, 0), 0)
            self.selectedRange = updated
            self.selectedRange = pristine
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
        let formatter = LinkFormatter()
        formatter.attributeValue = url        
        let attributes = formatter.apply(to: typingAttributes)
        storage.replaceCharacters(in: range, with: NSAttributedString(string: title, attributes: attributes))
        delegate?.textViewDidChange?(self)
    }


    /// Removes the link, if any, at the specified range
    ///
    /// - Parameter range: range that contains the link to be removed.
    ///
    open func removeLink(inRange range: NSRange) {
        let formatter = LinkFormatter()
        formatter.toggle(in: storage, at: range)
        delegate?.textViewDidChange?(self)
    }


    // MARK: - Embeds

    /// Inserts an image at the specified index
    ///
    /// - Parameters:
    ///     - image: the image object to be inserted.
    ///     - sourceURL: The url of the image to be inserted.
    ///     - position: The character index at which to insert the image.
    ///
    /// - Returns: the attachment object that can be used for further calls
    ///
    open func insertImage(sourceURL url: URL, atPosition position: Int, placeHolderImage: UIImage?, identifier: String = UUID().uuidString) -> TextAttachment {
        let attachment = storage.insertImage(sourceURL: url, atPosition: position, placeHolderImage: placeHolderImage ?? defaultMissingImage, identifier: identifier)
        let length = NSAttributedString(attachment:NSTextAttachment()).length
        textStorage.addAttributes(typingAttributes, range: NSMakeRange(position, length))
        selectedRange = NSMakeRange(position+length, 0)
        delegate?.textViewDidChange?(self)
        return attachment
    }


    /// Returns the TextAttachment instance with the matching identifier
    ///
    /// - Parameter id: Identifier of the text attachment to be retrieved
    ///
    open func attachment(withId id: String) -> TextAttachment? {
        return storage.attachment(withId: id)
    }

    /// Removes the attachments that match the attachament identifier provided from the storage
    ///
    /// - Parameter attachmentID: the unique id of the attachment
    ///
    open func remove(attachmentID: String) {
        storage.remove(attachmentID: attachmentID)
        delegate?.textViewDidChange?(self)
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

    /// Returns the associated TextAttachment, at a given point, if any.
    ///
    /// - Parameter point: The point on screen to check for attachments.
    ///
    /// - Returns: The associated TextAttachment.
    ///
    open func attachmentAtPoint(_ point: CGPoint) -> TextAttachment? {
        let index = layoutManager.characterIndex(for: point, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        guard index < textStorage.length else {
            return nil
        }

        return textStorage.attribute(NSAttachmentAttributeName, at: index, effectiveRange: nil) as? TextAttachment
    }

    /// Move the selected range to the nearest character of the point specified in the textView
    ///
    /// - Parameter point: the position to move the selection to.
    ///
    open func moveSelectionToPoint(_ point: CGPoint) {
        let index = layoutManager.characterIndex(for: point, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        guard index < textStorage.length else {
            return
        }

        selectedRange = NSRange(location: index + 1, length: 0)
        forceRedrawCursorAfterDelay()
    }

    // MARK: - Links

    /// Returns an NSURL if the specified range as attached a link attribute
    ///
    /// - Parameter range: The NSRange to inspect
    ///
    /// - Returns: The NSURL if available
    ///
    open func linkURL(forRange range: NSRange) -> URL? {
        let index = maxIndex(range.location)
        var effectiveRange = NSRange()
        guard index < storage.length,
            let attr = storage.attribute(NSLinkAttributeName, at: index, effectiveRange: &effectiveRange)
            else {
                return nil
        }

        if let url = attr as? URL {
            return url
        }

        if let urlString = attr as? String {
            return URL(string:urlString)
        }

        return nil
    }


    /// Returns the Link Attribute's Full Range, intersecting the specified range.
    ///
    /// - Parameter range: The NSRange to inspect
    ///
    /// - Returns: The full Link's Range.
    ///
    open func linkFullRange(forRange range: NSRange) -> NSRange? {
        let index = maxIndex(range.location)
        var effectiveRange = NSRange()
        guard index < storage.length,
            storage.attribute(NSLinkAttributeName, at: index, effectiveRange: &effectiveRange) != nil
            else {
                return nil
        }

        return effectiveRange
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
            return max(storage.length - 1, 0)
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
        delegate?.textViewDidChange?(self)
    }

    /// Invalidates the layout of the attachment and marks it to be refresh on the next update
    ///
    /// - Parameters:
    ///   - attachment: the attachment to update
    ///
    open func refreshLayoutFor(attachment: TextAttachment) {
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
    
    func storage(_ storage: TextStorage, urlForAttachment attachment: TextAttachment) -> URL {
        
        guard let mediaDelegate = mediaDelegate else {
            fatalError("This class requires a media delegate to be set.")
        }
        
        return mediaDelegate.textView(self, urlForAttachment: attachment)
    }

    func storage(_ storage: TextStorage, deletedAttachmentWithID attachmentID: String) {
        mediaDelegate?.textView(self, deletedAttachmentWithID: attachmentID)
    }
}
