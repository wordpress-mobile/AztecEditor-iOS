
import UIKit
import Foundation
import Gridicons


// MARK: - TextViewMediaDelegate
//
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
        urlForAttachment attachment: NSTextAttachment) -> URL


    /// Called when a attachment is removed from the storage.
    ///
    /// - Parameters:
    ///   - textView: The textView where the attachment was removed.
    ///   - attachmentID: The attachment identifier of the media removed.
    func textView(_ textView: TextView, deletedAttachmentWithID attachmentID: String)

    /// Called when an attachment is selected with a single tap.
    ///
    /// - Parameters:
    ///   - textView: the textview where the attachment is.
    ///   - attachment: the attachment that was selected.
    ///   - position: touch position relative to the textview.
    ///
    func textView(_ textView: TextView, selectedAttachment attachment: NSTextAttachment, atPosition position: CGPoint)

    /// Called when an attachment is deselected with a single tap.
    ///
    /// - Parameters:
    ///   - textView: the textview where the attachment is.
    ///   - attachment: the attachment that was deselected.
    ///   - position: touch position relative to the textView
    ///
    func textView(_ textView: TextView, deselectedAttachment attachment: NSTextAttachment, atPosition position: CGPoint)
}


// MARK: - TextViewAttachmentImageProvider
//
public protocol TextViewAttachmentImageProvider: class {

    /// Indicates whether the current Attachment Renderer supports a given NSTextAttachment instance, or not.
    ///
    /// - Parameters:
    ///     - textView: The textView that is requesting the bounds.
    ///     - attachment: Attachment about to be rendered.
    ///
    /// - Returns: True when supported, false otherwise.
    ///
    func textView(_ textView: TextView, shouldRender attachment: NSTextAttachment) -> Bool

    /// Provides the Bounds required to represent a given attachment, within a specified line fragment.
    ///
    /// - Parameters:
    ///     - textView: The textView that is requesting the bounds.
    ///     - attachment: Attachment about to be rendered.
    ///     - lineFragment: Line Fragment in which the glyph would be rendered.
    ///
    /// - Returns: Rect specifying the Bounds for the comment attachment
    ///
    func textView(_ textView: TextView, boundsFor attachment: NSTextAttachment, with lineFragment: CGRect) -> CGRect

    /// Provides the (Optional) Image Representation of the specified size, for a given Attachment.
    ///
    /// - Parameters:
    ///     - textView: The textView that is requesting the bounds.
    ///     - attachment: Attachment about to be rendered.
    ///     - size: Expected Image Size
    ///
    /// - Returns: (Optional) UIImage representation of the Comment Attachment.
    ///
    func textView(_ textView: TextView, imageFor attachment: NSTextAttachment, with size: CGSize) -> UIImage?
}


// MARK: - TextViewFormattingDelegate
//
public protocol TextViewFormattingDelegate: class {

    /// Called a text view command toggled a style.
    ///
    /// If you have a format bar, you should probably update it here.
    ///
    func textViewCommandToggledAStyle()
}


// MARK: - TextView
//
open class TextView: UITextView {

    typealias ElementNode = Libxml2.ElementNode


    // MARK: - Properties: Attachments & Media

    /// The media delegate takes care of providing remote media when requested by the `TextView`.
    /// If this is not set, all remove images will be left blank.
    ///
    open weak var mediaDelegate: TextViewMediaDelegate?

    /// Maintains a reference to the user provided Text Attachment Image Providers
    ///
    fileprivate var textAttachmentImageProvider = [TextViewAttachmentImageProvider]()

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
    }

    required public init?(coder aDecoder: NSCoder) {

        defaultFont = UIFont.systemFont(ofSize: 14)
        defaultMissingImage = Gridicon.iconOfType(.image)
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        allowsEditingTextAttributes = true
        storage.attachmentsDelegate = self
        font = defaultFont
        setupMenuController()
        setupAttachmentTouchDetection()
    }

    private func setupMenuController() {
        let pasteAndMatchTitle = NSLocalizedString("Paste and Match Style", comment: "Paste and Match Menu Item")
        let pasteAndMatchItem = UIMenuItem(title: pasteAndMatchTitle, action: #selector(pasteAndMatchStyle))
        UIMenuController.shared.menuItems = [pasteAndMatchItem]
    }

    fileprivate lazy var recognizerDelegate: AttachmentGestureRecognizerDelegate = {
        return AttachmentGestureRecognizerDelegate(textView: self)
    }()

    fileprivate lazy var attachmentGestureRecognizer: UITapGestureRecognizer = {
        let attachmentGestureRecognizer = UITapGestureRecognizer(target: self.recognizerDelegate, action: #selector(AttachmentGestureRecognizerDelegate.richTextViewWasPressed))
        attachmentGestureRecognizer.cancelsTouchesInView = true
        attachmentGestureRecognizer.delaysTouchesBegan = true
        attachmentGestureRecognizer.delaysTouchesEnded = true
        attachmentGestureRecognizer.delegate = self.recognizerDelegate
        return attachmentGestureRecognizer
    }()

    private func setupAttachmentTouchDetection() {
        for gesture in gestureRecognizers ?? [] {
            gesture.require(toFail: attachmentGestureRecognizer)
        }
        addGestureRecognizer(attachmentGestureRecognizer)
    }


    // MARK: - Overwritten Properties
    
    /// Overwrites Typing Attributes:
    /// This is the (only) valid hook we've found, in order to (selectively) remove the [Blockquote, List, Pre] attributes.
    /// For details, see: https://github.com/wordpress-mobile/AztecEditor-iOS/issues/414
    ///
    override open var typingAttributes: [String: Any] {
        get {
            ensureRemovalOfParagraphAttributes(at: selectedRange)
            return super.typingAttributes
        }
        set {
            super.typingAttributes = newValue
        }
    }


    // MARK: - Intercept copy paste operations

    open override func cut(_ sender: Any?) {
        let data = storage.attributedSubstring(from: selectedRange).archivedData()
        super.cut(sender)

        storeInPasteboard(encoded: data)
    }

    open override func copy(_ sender: Any?) {
        let data = storage.attributedSubstring(from: selectedRange).archivedData()
        super.copy(sender)

        storeInPasteboard(encoded: data)
    }

    open override func paste(_ sender: Any?) {
        guard let string = UIPasteboard.general.loadAttributedString() else {
            super.paste(sender)
            return
        }

        string.loadLazyAttachments()

        storage.replaceCharacters(in: selectedRange, with: string)
        delegate?.textViewDidChange?(self)
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
        delegate?.textViewDidChange?(self)
        selectedRange = NSRange(location: selectedRange.location + string.length, length: 0)
    }


    // MARK: - Pasteboard Helpers

    private func storeInPasteboard(encoded data: Data) {
        let pasteboard  = UIPasteboard.general
        pasteboard.items[0][NSAttributedString.pastesboardUTI] = data
    }


    // MARK: - Intercept keyboard operations

    open override func insertText(_ text: String) {

        /// Whenever the user is at the end of the document, while editing a [List, Blockquote, Pre], we'll need
        /// to insert a `\n` character, so that the Layout Manager immediately renders the List's new bullet
        /// (or Blockquote's BG).
        ///
        ensureInsertionOfNewline(beforeInserting: text)

        // Whenever the entered text causes the Paragraph Attributes to be removed, we should prevent the actual
        // text insertion to happen. Thus, we won't call super.insertText.
        // But because we don't call the super we need to refresh the attributes ourselfs, and callback to the delegate.
        //
        if ensureRemovalOfParagraphAttributes(beforeInserting: text, at: selectedRange) {
            if self.textStorage.length > 0 {
                typingAttributes = textStorage.attributes(at: min(selectedRange.location, textStorage.length-1), effectiveRange: nil)
            }

            delegate?.textViewDidChangeSelection?(self)
            delegate?.textViewDidChange?(self)

            return
        }

        // Emoji Fix:
        // Fallback to the default font, whenever the Active Font's Family doesn't match with the Default Font's family.
        // We do this twice (before and after inserting text), in order to properly handle two scenarios:
        //
        // - Before: Corrects the typing attributes in the scenario in which the user moves the cursor around.
        //   Placing the caret after an emoji might update the typing attributes, and in some scenarios, the SDK might
        //   fallback to Courier New.
        //
        // - After: If the user enters an Emoji, toggling Bold / Italics breaks. This is due to a glitch in the
        //   SDK: the font "applied" after inserting an emoji breaks with our styling mechanism.
        //
        restoreDefaultFontIfNeeded()

        ensureRemovalOfLinkTypingAttribute(at: selectedRange)
        ensureRemovalOfVisualOnlyTypingAttribute()

        super.insertText(text)

        restoreDefaultFontIfNeeded()

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

        refreshStylesAfterDeletion(of: deletedString, at: deletionRange)
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


    // MARK: - Attachment Helpers

    open func registerAttachmentImageProvider(_ provider: TextViewAttachmentImageProvider) {
        textAttachmentImageProvider.append(provider)
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
        .header1: HeaderFormatter(headerLevel: .h1, placeholderAttributes: nil),
        .header2: HeaderFormatter(headerLevel: .h2, placeholderAttributes: nil),
        .header3: HeaderFormatter(headerLevel: .h3, placeholderAttributes: nil),
        .header4: HeaderFormatter(headerLevel: .h4, placeholderAttributes: nil),
        .header5: HeaderFormatter(headerLevel: .h5, placeholderAttributes: nil),
        .header6: HeaderFormatter(headerLevel: .h6, placeholderAttributes: nil),
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
        let applicationRange = storage.toggle(formatter: formatter, at: range)
        if applicationRange.length == 0 {
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

    /// Adds or removes a Pre style from the specified range.
    /// Pre are applied to an entire paragrah regardless of the range.
    /// If the range spans multiple paragraphs, the style is applied to all
    /// affected paragraphs.
    ///
    /// - Parameters:
    ///     - range: The NSRange to edit.
    ///
    open func togglePre(range: NSRange) {
        ensureInsertionOfNewlineWhenEditingEdgeOfTheDocument()

        let formatter = PreFormatter(placeholderAttributes: typingAttributes)
        toggle(formatter: formatter, atRange: range)

        forceRedrawCursorAfterDelay()
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
        ensureInsertionOfNewlineWhenEditingEdgeOfTheDocument()

        let formatter = BlockquoteFormatter(placeholderAttributes: typingAttributes)
        toggle(formatter: formatter, atRange: range)

        forceRedrawCursorAfterDelay()
    }

    /// Adds or removes a ordered list style from the specified range.
    ///
    /// - Parameter range: The NSRange to edit.
    ///
    open func toggleOrderedList(range: NSRange) {
        ensureInsertionOfNewlineWhenEditingEdgeOfTheDocument()

        let formatter = TextListFormatter(style: .ordered, placeholderAttributes: typingAttributes)
        toggle(formatter: formatter, atRange: range)

        forceRedrawCursorAfterDelay()
    }


    /// Adds or removes a unordered list style from the specified range.
    ///
    /// - Parameter range: The NSRange to edit.
    ///
    open func toggleUnorderedList(range: NSRange) {
        ensureInsertionOfNewlineWhenEditingEdgeOfTheDocument()

        let formatter = TextListFormatter(style: .unordered, placeholderAttributes: typingAttributes)
        toggle(formatter: formatter, atRange: range)

        forceRedrawCursorAfterDelay()
    }


    /// Adds or removes a unordered list style from the specified range.
    ///
    /// - Parameter range: The NSRange to edit.
    ///
    open func toggleHeader(_ headerType: HeaderFormatter.HeaderType, range: NSRange) {
        let formatter = HeaderFormatter(headerLevel: headerType, placeholderAttributes: typingAttributes)
        toggle(formatter: formatter, atRange: range)
        forceRedrawCursorAfterDelay()
    }

    /// Inserts an horizontal ruler on the specified range
    ///
    /// - Parameter range: the range where the ruler will be inserted
    ///
    open func replaceRangeWithHorizontalRuler(_ range: NSRange) {
        storage.replaceRangeWithHorizontalRuler(range)
        let length = NSAttributedString(attachment:NSTextAttachment()).length
        textStorage.addAttributes(typingAttributes, range: NSMakeRange(range.location, length))
        selectedRange = NSMakeRange(range.location + length, 0)
        delegate?.textViewDidChange?(self)
    }

    fileprivate lazy var defaultAttributes: [String: Any] = {
        return [
            NSFontAttributeName: self.defaultFont,
            NSParagraphStyleAttributeName: ParagraphStyle.default
        ]
    }()

    private lazy var paragraphFormatters: [AttributeFormatter] = [
        BlockquoteFormatter(),
        HeaderFormatter(headerLevel:.h1),
        HeaderFormatter(headerLevel:.h2),
        HeaderFormatter(headerLevel:.h3),
        HeaderFormatter(headerLevel:.h4),
        HeaderFormatter(headerLevel:.h5),
        HeaderFormatter(headerLevel:.h6),
        PreFormatter(placeholderAttributes: self.defaultAttributes)
    ]

    /// After text deletion, this helper will re-apply the Text Formatters at the specified range, if they were
    /// present in the segment previous to the modified range.
    ///
    /// - Parameters:
    ///     - deletedText: String that was deleted.
    ///     - range: Position in which the deletedText was present in the storage.
    ///
    private func refreshStylesAfterDeletion(of deletedText: NSAttributedString, at range: NSRange) {
        guard deletedText.string == String(.newline) || range.location == 0 else {
            return
        }

        for formatter in paragraphFormatters {
            if let locationBefore = storage.string.location(before: range.location),
                formatter.present(in: textStorage, at: locationBefore) {
                if range.endLocation < storage.length {
                    formatter.applyAttributes(to: storage, at: range)
                }
            }
        }
    }


    /// Verifies if the Active Font's Family Name matches with our Default Font, or not. If the family diverges,
    /// this helper will proceed to restore the defaultFont's Typing Attributes
    /// This is meant as a workaround for the "Emojis Mixing Up Font's" glitch.
    ///
    private func restoreDefaultFontIfNeeded() {
        guard let activeFont = typingAttributes[NSFontAttributeName] as? UIFont, activeFont.isAppleEmojiFont else {
            return
        }

        typingAttributes[NSFontAttributeName] = defaultFont.withSize(activeFont.pointSize)
    }


    /// Inserts an empty line whenever we're at the end of the document
    ///
    private func ensureInsertionOfNewlineWhenEditingEdgeOfTheDocument() {
        guard selectedRange.location == storage.length else {
            return
        }

        insertNewline()
    }


    /// Inserts an empty line whenever:
    ///
    ///     A.  We're about to insert a new line
    ///     B.  We're at the end of the document
    ///     C.  There's a List (OR) Blockquote (OR) Pre active
    ///
    /// We're doing this as a workaround, in order to force the LayoutManager render the Bullet (OR) 
    /// Blockquote's background.
    ///
    private func ensureInsertionOfNewline(beforeInserting text: String) {
        guard text == String(.newline) else {
            return
        }

        guard selectedRange.location == storage.length else {
            return
        }

        let formatters: [AttributeFormatter] = [
            BlockquoteFormatter(),
            PreFormatter(placeholderAttributes: self.defaultAttributes),
            TextListFormatter(style: .ordered),
            TextListFormatter(style: .unordered)
        ]

        let found = formatters.first { formatter in
            return formatter.present(in: typingAttributes)
        }

        guard found != nil else {
            return
        }

        insertNewline()
    }


    /// Inserts a New Line at the current position, while retaining the selectedRange and typingAttributes.
    ///
    private func insertNewline() {
        let previousRange = selectedRange
        let previousStyle = typingAttributes

        super.insertText(String(.newline))

        selectedRange = previousRange
        typingAttributes = previousStyle
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


    /// Upon Text Insertion, we'll remove the NSLinkAttribute whenever the new text **IS NOT** surrounded by
    /// the NSLinkAttribute. Meaning that:
    ///
    ///     - Text inserted in front of a link will not be automagically linkified
    ///     - Text inserted after a link (even with no spaces!) won't be linkified anymore
    ///     - Only text edited "Within" a Link's Anchor will get linkified.
    ///
    /// - Parameter range: Range in which new text will be inserted.
    ///
    private func ensureRemovalOfLinkTypingAttribute(at range: NSRange) {
        guard typingAttributes[NSLinkAttributeName] != nil else {
            return
        }

        guard !storage.isLocationPreceededByLink(range.location) ||
            !storage.isLocationSuccededByLink(range.location)
            else {
                return
        }

        typingAttributes.removeValue(forKey: NSLinkAttributeName)
    }

    /// Ensures the removal of visual-only typing attributes.  Visual-only elements can never
    /// be introduced by keyboard input.
    ///
    private func ensureRemovalOfVisualOnlyTypingAttribute() {
        typingAttributes[VisualOnlyAttributeName] = nil
    }


    private let formattersThatBreakAfterEnter: [AttributeFormatter] = [
        HeaderFormatter(headerLevel:.h1),
        HeaderFormatter(headerLevel:.h2),
        HeaderFormatter(headerLevel:.h3),
        HeaderFormatter(headerLevel:.h4),
        HeaderFormatter(headerLevel:.h5),
        HeaderFormatter(headerLevel:.h6),
    ]
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

        for formatter in formattersThatBreakAfterEnter {
            if formatter.present(in: typingAttributes) {
                typingAttributes = formatter.remove(from: typingAttributes)
                return true
            }
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
            let beforeTypingAttributes = self.typingAttributes
            self.selectedRange = updated
            self.selectedRange = pristine
            self.typingAttributes = beforeTypingAttributes
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
        let linkWasPresent = formatter.present(in: storage, at: range)
        storage.replaceCharacters(in: range, with: NSAttributedString(string: title, attributes: attributes))
        if range.length == 0 && !linkWasPresent {
            selectedRange = NSMakeRange(range.location + (title as NSString).length, 0)
        }
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
    open func insertImage(sourceURL url: URL, atPosition position: Int, placeHolderImage: UIImage?, identifier: String = UUID().uuidString) -> ImageAttachment {
        let attachment = storage.insertImage(sourceURL: url, atPosition: position, placeHolderImage: placeHolderImage ?? defaultMissingImage, identifier: identifier)
        let length = NSAttributedString.lengthOfTextAttachment
        textStorage.addAttributes(typingAttributes, range: NSMakeRange(position, length))
        selectedRange = NSMakeRange(position+length, 0)
        delegate?.textViewDidChange?(self)
        return attachment
    }


    /// Returns the MediaAttachment instance with the matching identifier
    ///
    /// - Parameter id: Identifier of the text attachment to be retrieved
    ///
    open func attachment(withId id: String) -> MediaAttachment? {
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

    /// Removes all of the text attachments contained within the storage
    ///
    open func removeTextAttachments() {
        storage.removeMediaAttachments()
        delegate?.textViewDidChange?(self)
    }

    /// Inserts a Video attachment at the specified index
    ///
    /// - Parameters:
    ///   - location: the location in the text to insert the video
    ///   - sourceURL: the video source URL
    ///   - posterURL: the video poster image URL
    ///   - placeHolderImage: an image to use has an placeholder while the video poster is being loaded
    ///   - identifier: an unique indentifier for the video
    ///
    /// - Returns: the video attachment object that was inserted.
    ///
    open func insertVideo(atLocation location: Int, sourceURL: URL, posterURL: URL?, placeHolderImage: UIImage?, identifier: String = UUID().uuidString) -> VideoAttachment {
        let attachment = storage.insertVideo(sourceURL: sourceURL, posterURL: posterURL, atPosition: location, placeHolderImage: placeHolderImage ?? defaultMissingImage, identifier: identifier)
        let length = NSAttributedString.lengthOfTextAttachment
        textStorage.addAttributes(typingAttributes, range: NSMakeRange(location, length))
        selectedRange = NSMakeRange(location+length, 0)
        delegate?.textViewDidChange?(self)
        return attachment
    }

    /// Returns the associated TextAttachment, at a given point, if any.
    ///
    /// - Parameter point: The point on screen to check for attachments.
    ///
    /// - Returns: The associated TextAttachment.
    ///
    open func attachmentAtPoint(_ point: CGPoint) -> NSTextAttachment? {
        let index = layoutManager.characterIndex(for: point, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        guard index < textStorage.length else {
            return nil
        }

        return textStorage.attribute(NSAttachmentAttributeName, at: index, effectiveRange: nil) as? NSTextAttachment
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

        guard let locationAfter = textStorage.string.location(after: index) else {
            selectedRange = NSRange(location: index, length: 0)
            return;
        }
        var newLocation = locationAfter
        if isPointInsideAttachmentMargin(point: point) {
            newLocation = index
        }
        selectedRange = NSRange(location: newLocation, length: 0)
    }


    /// // Check if there is an attachment at the location we are moving. If there is one check if we want to move before or after the attachment based on the margins.
    ///
    /// - Parameter point: the point to check.
    /// - Returns: true if the point fall inside an attachment margin
    open func isPointInsideAttachmentMargin(point: CGPoint) -> Bool {
        let index = layoutManager.characterIndex(for: point, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)

        if let attachment = attachmentAtPoint(point) as? MediaAttachment {
            let glyphRange = layoutManager.glyphRange(forCharacterRange: NSRange(location: index, length: 1), actualCharacterRange: nil)
            let rect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
            if point.y >= rect.origin.y && point.y <= (rect.origin.y + (2*attachment.imageMargin)) {
                return true
            }
        }
        return false
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
    open func update(attachment: ImageAttachment,
                     alignment: ImageAttachment.Alignment,
                     size: ImageAttachment.Size,
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
    open func refreshLayoutFor(attachment: MediaAttachment) {
        layoutManager.invalidateLayoutForAttachment(attachment)
    }


    // MARK: - More

    /// Inserts an HTML Comment at the specified position.
    ///
    /// - Parameters:
    ///     - range: The character range that must be replaced with a Comment Attachment.
    ///     - text: The Comment Attachment's Text.
    ///
    /// - Returns: the attachment object that can be used for further calls
    ///
    @discardableResult
    open func replaceRangeWithCommentAttachment(_ range: NSRange, text: String) -> CommentAttachment {
        let attachment = storage.replaceRangeWithCommentAttachment(range, text: text, attributes: typingAttributes)

        selectedRange = NSMakeRange(range.location + NSAttributedString.lengthOfTextAttachment, 0)
        delegate?.textViewDidChange?(self)

        return attachment
    }
}

// MARK: - Paragraph Formatters Rendering Workarounds
//
private extension TextView {

    /// Removes the Paragraph Attributes whenever `mustRemoveParagraphAttributes(beforeInserting: at)` returns true.
    ///
    /// - Parameters:
    ///     - text: (Optional) String that's about to be inserted.
    ///     - selectedRange: TextView's Selected Range.
    ///
    /// - Returns: true if ParagraphAttributes were removed. false otherwise!
    ///
    @discardableResult
    func ensureRemovalOfParagraphAttributes(beforeInserting text: String? = nil, at selectedRange: NSRange) -> Bool {
        guard mustRemoveParagraphAttributes(beforeInserting: text, at: selectedRange.location) else {
            return false
        }

        return removeParagraphAttributes(at: selectedRange)
    }


    /// Analyzes whether the Paragraph Attributes should be removed at a specified location, or not.
    /// This is necessary in two different scenarios:
    ///
    /// Scenario A:
    ///
    ///     A. We're at the end of the document
    ///     B. Below there's an empty line.
    ///     C. The user pressed Arrow Down
    ///
    ///     Why: We only want to carry over the `Paragraph Attribute` if a Newline is explicitly pressed.
    ///
    /// Scenario B:
    ///
    ///     A. The user enters a newline
    ///     B. The next character is a newline (OR) there is no next character
    ///     C. The previous character is a newline (OR) there is no previous character
    ///
    ///     Why: We wanna take care of removing [Lists, Pre, Blockquotes] if the user hits return on an empty line.
    ///
    ///
    /// - Parameters:
    ///     - text: String that is about to be inserted.
    ///     - location: Selected Range's Location
    ///
    /// - Returns: true if we should remove the paragraph attributes. false otherwise!
    ///
    func mustRemoveParagraphAttributes(beforeInserting text: String? = nil, at location: Int) -> Bool {
        guard text == String(.newline) || location == storage.length else {
            return false
        }

        let afterRange = NSRange(location: location, length: 1)
        let afterString = storage.safeSubstring(at: afterRange) ?? String(.newline)

        let beforeRange = NSRange(location: location - 1, length: 1)
        let beforeString = storage.safeSubstring(at: beforeRange) ?? String(.newline)

        return beforeString == String(.newline) && afterString == String(.newline)
    }


    /// Removes the Paragraph Attributes [Blockquote, Pre, Lists] at the specified range. If the range
    /// is beyond the storage's contents, the typingAttributes will be modified
    ///
    /// - Returns: true on success.
    ///
    func removeParagraphAttributes(at range: NSRange) -> Bool {
        let formatters: [AttributeFormatter] = [
            BlockquoteFormatter(),
            PreFormatter(placeholderAttributes: defaultAttributes),
            TextListFormatter(style: .ordered),
            TextListFormatter(style: .unordered)
        ]

        guard range.location >= storage.length else {
            for formatter in formatters where formatter.present(in: textStorage, at: range.location) {
                formatter.removeAttributes(from: textStorage, at: range)
                return true
            }

            return false
        }

        for formatter in formatters where formatter.present(in: super.typingAttributes) {
            super.typingAttributes = formatter.remove(from: super.typingAttributes)
            return true
        }
        
        return false
    }
}


// MARK: - TextStorageImageProvider
//
extension TextView: TextStorageAttachmentsDelegate {

    func storage(
        _ storage: TextStorage,
        attachment: NSTextAttachment,
        imageForURL url: URL,
        onSuccess success: @escaping (UIImage) -> (),
        onFailure failure: @escaping () -> ()) -> UIImage {
        
        guard let mediaDelegate = mediaDelegate else {
            fatalError("This class requires a media delegate to be set.")
        }
        
        let placeholderImage = mediaDelegate.textView(self, imageAtUrl: url, onSuccess: success, onFailure: failure)
        return placeholderImage
    }

    func storage(_ storage: TextStorage, missingImageForAttachment: NSTextAttachment) -> UIImage {
        return defaultMissingImage
    }
    
    func storage(_ storage: TextStorage, urlForAttachment attachment: NSTextAttachment) -> URL {
        guard let mediaDelegate = mediaDelegate else {
            fatalError("This class requires a media delegate to be set.")
        }
        
        return mediaDelegate.textView(self, urlForAttachment: attachment)
    }

    func storage(_ storage: TextStorage, deletedAttachmentWithID attachmentID: String) {
        mediaDelegate?.textView(self, deletedAttachmentWithID: attachmentID)
    }

    func storage(_ storage: TextStorage, imageFor attachment: NSTextAttachment, with size: CGSize) -> UIImage? {
        let provider = textAttachmentImageProvider.first { provider in
            return provider.textView(self, shouldRender: attachment)
        }

        guard let firstProvider = provider else {
            fatalError("This class requires at least one AttachmentImageProvider to be set.")
        }

        return firstProvider.textView(self, imageFor: attachment, with: size)
    }

    func storage(_ storage: TextStorage, boundsFor attachment: NSTextAttachment, with lineFragment: CGRect) -> CGRect {
        let provider = textAttachmentImageProvider.first {
            $0.textView(self, shouldRender: attachment)
        }

        guard let firstProvider = provider else {
            fatalError("This class requires at least one AttachmentImageProvider to be set.")
        }

        return firstProvider.textView(self, boundsFor: attachment, with: lineFragment)
    }
}


// MARK: - UIGestureRecognizerDelegate
//
@objc class AttachmentGestureRecognizerDelegate: NSObject, UIGestureRecognizerDelegate
{
    let textView: TextView
    fileprivate var currentSelectedAttachment: ImageAttachment?

    public init(textView: TextView) {
        self.textView = textView
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {

        let locationInTextView = gestureRecognizer.location(in: textView)
        // check if we have an attachment in the position we tapped
        guard textView.attachmentAtPoint(locationInTextView) != nil else {
            // if we have a current selected attachment let's notify of deselection
            if let selectedAttachment = currentSelectedAttachment {
                textView.mediaDelegate?.textView(textView, deselectedAttachment: selectedAttachment, atPosition: locationInTextView)
            }
            currentSelectedAttachment = nil
            return false
        }
        return true
    }

    func richTextViewWasPressed(_ recognizer: UIGestureRecognizer) {
        guard recognizer.state == .recognized else {
            return
        }
        let locationInTextView = recognizer.location(in: textView)
        // check if we have an attachment in the position we tapped
        guard let attachment = textView.attachmentAtPoint(locationInTextView) else {
            return
        }

        // move the selection to the position of the attachment

        textView.moveSelectionToPoint(locationInTextView)

        if textView.isPointInsideAttachmentMargin(point: locationInTextView) {
            if let selectedAttachment = currentSelectedAttachment {
                textView.mediaDelegate?.textView(textView, deselectedAttachment: selectedAttachment, atPosition: locationInTextView)
            }
            currentSelectedAttachment = nil
            return
        }

        currentSelectedAttachment = attachment as? ImageAttachment
        textView.mediaDelegate?.textView(textView, selectedAttachment: attachment, atPosition: locationInTextView)
    }
}

