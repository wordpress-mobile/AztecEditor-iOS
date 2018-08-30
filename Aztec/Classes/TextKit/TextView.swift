import UIKit
import Foundation


// MARK: - TextViewAttachmentDelegate
//
public protocol TextViewAttachmentDelegate: class {

    /// This method requests from the delegate the image at the specified URL.
    ///
    /// - Parameters:
    ///     - textView: the `TextView` the call has been made from.
    ///     - attachment: the attachment that is requesting the image
    ///     - imageURL: the url to download the image from.
    ///     - success: when the image is obtained, this closure should be executed.
    ///     - failure: if the image cannot be obtained, this closure should be executed.
    ///
    func textView(_ textView: TextView,
                  attachment: NSTextAttachment,
                  imageAt url: URL,
                  onSuccess success: @escaping (UIImage) -> Void,
                  onFailure failure: @escaping () -> Void)

    /// Called when an attachment is about to be added to the storage as an attachment (copy/paste), so that the
    /// delegate can specify an URL where that attachment is available.
    ///
    /// - Parameters:
    ///     - textView: The textView that is requesting the image.
    ///     - imageAttachment: The image attachment that was added to the storage.
    ///
    /// - Returns: the requested `URL` where the image is stored, or nil if it's not yet available.
    ///
    func textView(_ textView: TextView, urlFor imageAttachment: ImageAttachment) -> URL?

    /// Called when an attachment doesn't have an available source URL to provide an image representation.
    ///
    /// - Parameters:
    ///   - textView: the textview that is requesting the image
    ///   - attachment: the attachment that does not an have image source
    ///
    /// - Returns: an UIImage to represent the attachment graphically
    ///
    func textView(_ textView: TextView, placeholderFor attachment: NSTextAttachment) -> UIImage

    /// Called after a attachment is removed from the storage.
    ///
    /// - Parameters:
    ///   - textView: The textView where the attachment was removed.
    ///   - attachment: The media attachment that was removed.
    ///
    func textView(_ textView: TextView, deletedAttachment attachment: MediaAttachment)

    /// Called after an attachment is selected with a single tap.
    ///
    /// - Parameters:
    ///   - textView: the textview where the attachment is.
    ///   - attachment: the attachment that was selected.
    ///   - position: touch position relative to the textview.
    ///
    func textView(_ textView: TextView, selected attachment: NSTextAttachment, atPosition position: CGPoint)

    /// Called after an attachment is deselected with a single tap.
    ///
    /// - Parameters:
    ///   - textView: the textview where the attachment is.
    ///   - attachment: the attachment that was deselected.
    ///   - position: touch position relative to the textView
    ///
    func textView(_ textView: TextView, deselected attachment: NSTextAttachment, atPosition position: CGPoint)
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

    // MARK: - Aztec Delegates

    /// The media delegate takes care of providing remote media when requested by the `TextView`.
    /// If this is not set, all remove images will be left blank.
    ///
    open weak var textAttachmentDelegate: TextViewAttachmentDelegate?

    /// Maintains a reference to the user provided Text Attachment Image Providers
    ///
    fileprivate var textAttachmentImageProvider = [TextViewAttachmentImageProvider]()

    /// Formatting Delegate: to be used by the Edition's Format Bar.
    ///
    open weak var formattingDelegate: TextViewFormattingDelegate?
    
    // MARK: - Behavior configuration
    
    private static let singleLineParagraphFormatters: [AttributeFormatter] = [
        HeaderFormatter(headerLevel: .h1, placeholderAttributes: [:]),
        HeaderFormatter(headerLevel: .h2, placeholderAttributes: [:]),
        HeaderFormatter(headerLevel: .h3, placeholderAttributes: [:]),
        HeaderFormatter(headerLevel: .h4, placeholderAttributes: [:]),
        HeaderFormatter(headerLevel: .h5, placeholderAttributes: [:]),
        HeaderFormatter(headerLevel: .h6, placeholderAttributes: [:]),
        FigureFormatter(placeholderAttributes: [:]),
        FigcaptionFormatter(placeholderAttributes: [:]),
    ]

    // MARK: - Properties: Text Lists

    var maximumListIndentationLevels = 7

    // MARK: - Properties: UI Defaults

    public let defaultFont: UIFont
    public let defaultParagraphStyle: ParagraphStyle
    var defaultMissingImage: UIImage
    
    fileprivate var defaultAttributes: [NSAttributedString.Key: Any] {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: defaultFont,
            .paragraphStyle: defaultParagraphStyle
        ]

        return attributes
    }
    
    /// This closure will be executed whenever the `TextView` needs to set the base style for
    /// a caption.  Override this to customize the caption styling.
    ///
    public lazy var captionStyler: ([NSAttributedString.Key:Any]) -> [NSAttributedString.Key:Any] = { [weak self] attributes in
        guard let `self` = self else {
            return attributes
        }
        
        let font = self.defaultFont.withSize(10)
        
        var attributes = attributes
        attributes[.font] = font
        attributes[.foregroundColor] = UIColor.darkGray
        
        return attributes
    }
    
    // MARK: - Plugin Loading
    
    var pluginManager: PluginManager {
        get {
            return storage.pluginManager
        }
    }
    
    public func load(_ plugin: Plugin) {
        pluginManager.load(plugin)
    }

    // MARK: - TextKit Aztec Subclasses

    var storage: TextStorage {
        return textStorage as! TextStorage
    }

    var layout: LayoutManager {
        return layoutManager as! LayoutManager
    }


    // MARK: - Apparance Properties

    /// Blockquote Blocks Border Color.
    ///
    @objc dynamic public var blockquoteBorderColor: UIColor {
        get {
            return layout.blockquoteBorderColor
        }
        set {
            layout.blockquoteBorderColor = newValue
        }
    }

    /// Blockquote Blocks Background Color.
    ///
    @objc dynamic public var blockquoteBackgroundColor: UIColor {
        get {
            return layout.blockquoteBackgroundColor
        }
        set {
            layout.blockquoteBackgroundColor = newValue
        }
    }


    /// Blockquote Blocks Background Width.
    ///
    @objc dynamic public var blockquoteBorderWidth: CGFloat {
        get {
            return layout.blockquoteBorderWidth
        }
        set {
            layout.blockquoteBorderWidth = newValue
        }
    }

    /// Pre Blocks Background Color.
    ///
    @objc dynamic public var preBackgroundColor: UIColor {
        get {
            return layout.preBackgroundColor
        }
        set {
            layout.preBackgroundColor = newValue
        }
    }


    // MARK: - Overwritten Properties
    
    /// Overwrites Typing Attributes:
    /// This is the (only) valid hook we've found, in order to (selectively) remove the [Blockquote, List, Pre] attributes.
    /// For details, see: https://github.com/wordpress-mobile/AztecEditor-iOS/issues/414
    ///
    override open var typingAttributes: [NSAttributedString.Key: Any] {
        get {
            ensureRemovalOfParagraphAttributesAfterSelectionChange()
            return super.typingAttributes
        }
        set {
            super.typingAttributes = newValue
        }
    }


    /// This property returns the Attributes associated to the Extra Line Fragment.
    ///
    public var extraLineFragmentTypingAttributes: [NSAttributedString.Key: Any] {
        guard selectedTextRange?.start != endOfDocument else {
            return typingAttributes
        }

        let string = textStorage.string
        
        guard !string.isEndOfParagraph(before: string.endIndex) else {
            return defaultAttributes
        }
        
        let lastLocation = max(string.count - 1, 0)
        
        return textStorage.attributes(at: lastLocation, effectiveRange: nil)
    }


    // MARK: - Init & deinit

    @objc public init(
        defaultFont: UIFont,
        defaultParagraphStyle: ParagraphStyle = ParagraphStyle.default,
        defaultMissingImage: UIImage) {

        if #available(iOS 11.0, *) {
            self.defaultFont = UIFontMetrics.default.scaledFont(for: defaultFont)
        } else {
            self.defaultFont = defaultFont
        }
        self.defaultParagraphStyle = defaultParagraphStyle
        self.defaultMissingImage = defaultMissingImage

        let storage = TextStorage()
        let layoutManager = LayoutManager()
        let container = NSTextContainer()

        container.widthTracksTextView = true
        storage.addLayoutManager(layoutManager)
        layoutManager.addTextContainer(container)

        super.init(frame: CGRect(x: 0, y: 0, width: 10, height: 10), textContainer: container)
        commonInit()
    }

    required public init?(coder aDecoder: NSCoder) {
        let font = UIFont.systemFont(ofSize: 14)
        if #available(iOS 11.0, *) {
            self.defaultFont = UIFontMetrics.default.scaledFont(for: font)
        } else {
            self.defaultFont = font
        }

        defaultParagraphStyle = ParagraphStyle.default
        defaultMissingImage = Assets.imageIcon
        
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        allowsEditingTextAttributes = true
        if #available(iOS 10.0, *) {
            adjustsFontForContentSizeCategory = true
        }
        storage.attachmentsDelegate = self
        font = defaultFont
        linkTextAttributes = [.underlineStyle: NSNumber(value: NSUnderlineStyle.single.rawValue), .foregroundColor: self.tintColor]
        typingAttributes = defaultAttributes
        setupMenuController()
        setupAttachmentTouchDetection()
        setupLayoutManager()
    }

    private func setupMenuController() {
        let pasteAndMatchTitle = NSLocalizedString("Paste without Formatting", comment: "Paste without Formatting Menu Item")
        let pasteAndMatchItem = UIMenuItem(title: pasteAndMatchTitle, action: #selector(pasteWithoutFormatting))
        UIMenuController.shared.menuItems = [pasteAndMatchItem]
    }

    fileprivate lazy var recognizerDelegate: AttachmentGestureRecognizerDelegate = {
        return AttachmentGestureRecognizerDelegate(textView: self)
    }()

    fileprivate lazy var attachmentGestureRecognizer: UITapGestureRecognizer = { [unowned self] in
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

    private func setupLayoutManager() {
        guard let aztecLayoutManager = layoutManager as? LayoutManager else {
            return
        }

        aztecLayoutManager.extraLineFragmentTypingAttributes = { [weak self] in
            return self?.extraLineFragmentTypingAttributes ?? [:]
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
        let pasteHandled = tryPastingURL() || tryPastingHTML() || tryPastingAttributedString() || tryPastingString()
        
        guard pasteHandled else {
            super.paste(sender)
            return
        }
    }

    @objc open func pasteWithoutFormatting(_ sender: Any?) {
        guard tryPastingString() else {
            super.paste(sender)
            return
        }
    }
    
    // MARK: - Try Pasting
    
    /// Tries to paste an attributed string from the clipboard as source, replacing the selected range.
    ///
    /// - Returns: True if this method succeeds.
    ///
    private func tryPastingAttributedString() -> Bool {
        guard let string = UIPasteboard.general.attributedString() else {
            return false
        }
        
        let finalRange = NSRange(location: selectedRange.location, length: string.length)
        let originalText = attributedText.attributedSubstring(from: selectedRange)
        
        undoManager?.registerUndo(withTarget: self, handler: { [weak self] target in
            self?.undoTextReplacement(of: originalText, finalRange: finalRange)
        })
        
        string.loadLazyAttachments()
        
        storage.replaceCharacters(in: selectedRange, with: string)
        notifyTextViewDidChange()
        selectedRange = NSRange(location: selectedRange.location + string.length, length: 0)
        return true
    }

    /// Tries to paste HTML from the clipboard as source, replacing the selected range.
    ///
    /// - Returns: True if this method succeeds.
    ///
    func tryPastingHTML() -> Bool {
        guard let html = UIPasteboard.general.html() else {
            return false
        }

        replace(selectedRange, withHTML: html)
        return true
    }

    /// Tries to paste raw text from the clipboard, replacing the selected range.
    ///
    /// - Returns: True if this method succeeds.
    ///
    private func tryPastingString() -> Bool {
        guard let string = UIPasteboard.general.attributedString() else {
            return false
        }

        let finalRange = NSRange(location: selectedRange.location, length: string.length)
        let originalText = attributedText.attributedSubstring(from: selectedRange)

        undoManager?.registerUndo(withTarget: self, handler: { [weak self] target in
            self?.undoTextReplacement(of: originalText, finalRange: finalRange)
        })
        
        let newString = NSMutableAttributedString(attributedString: string)
        
        string.enumerateAttributes(in: string.rangeOfEntireString, options: []) { (attributes, range, stop) in
            let newAttributes = attributes.filter({ (key, value) -> Bool in
                return value is NSTextAttachment
            })
            
            newString.setAttributes(newAttributes, range: range)
        }
        
        newString.addAttributes(typingAttributes, range: string.rangeOfEntireString)
        newString.loadLazyAttachments()

        storage.replaceCharacters(in: selectedRange, with: newString)
        notifyTextViewDidChange()
        selectedRange = NSRange(location: selectedRange.location + newString.length, length: 0)
        return true
    }

    /// Tries to paste a URL from the clipboard as a link applied to the selected range.
    ///
    /// - Returns: True if this method succeeds.
    ///
    private func tryPastingURL() -> Bool {
        guard selectedRange.length > 0,
            let url = UIPasteboard.general.url() else {
                return false
        }
        
        setLink(url, inRange: selectedRange)
        return true
    }

    // MARK: - Intercept Keystrokes

    override open var keyCommands: [UIKeyCommand]? {
        get {
            // When the keyboard "enter" key is pressed, the keycode corresponds to .carriageReturn,
            // even if it's later converted to .lineFeed by default.
            //
            return [
                UIKeyCommand(input: String(.carriageReturn), modifierFlags: .shift, action: #selector(handleShiftEnter(command:))),
                UIKeyCommand(input: String(.tab), modifierFlags: .shift, action: #selector(handleShiftTab(command:))),
                UIKeyCommand(input: String(.tab), modifierFlags: [], action: #selector(handleTab(command:)))
            ]
        }
    }

    @objc func handleShiftEnter(command: UIKeyCommand) {
        insertText(String(.lineSeparator))
    }

    @objc func handleShiftTab(command: UIKeyCommand) {
        guard let list = TextListFormatter.lists(in: typingAttributes).last else {
            return
        }

        let formatter = TextListFormatter(style: list.style, placeholderAttributes: nil, increaseDepth: true)
        let liFormatter = LiFormatter(placeholderAttributes: nil)
        let targetRange = formatter.applicationRange(for: selectedRange, in: storage)

        performUndoable(at: targetRange) {
            let finalRange = formatter.removeAttributes(from: storage, at: targetRange)
            liFormatter.removeAttributes(from: storage, at: targetRange)
            typingAttributes = textStorage.attributes(at: targetRange.location, effectiveRange: nil)
            return finalRange
        }
    }

    @objc func handleTab(command: UIKeyCommand) {
        let lists = TextListFormatter.lists(in: typingAttributes)
        guard let list = lists.last, lists.count < maximumListIndentationLevels else {
            insertText(String(.tab))
            return
        }

        let formatter = TextListFormatter(style: list.style, placeholderAttributes: nil, increaseDepth: true)
        let liFormatter = LiFormatter(placeholderAttributes: nil)
        let targetRange = formatter.applicationRange(for: selectedRange, in: storage)

        performUndoable(at: targetRange) { 
            let finalRange = formatter.applyAttributes(to: storage, at: targetRange)
            liFormatter.applyAttributes(to: storage, at: targetRange)
            typingAttributes = textStorage.attributes(at: targetRange.location, effectiveRange: nil)
            return finalRange
        }
    }


    // MARK: - Pasteboard Helpers

    private func storeInPasteboard(encoded data: Data) {
        let pasteboard = UIPasteboard.general
        pasteboard.items[0][NSAttributedString.pastesboardUTI] = data
    }

    fileprivate func notifyTextViewDidChange() {
        delegate?.textViewDidChange?(self)
        NotificationCenter.default.post(name: UITextView.textDidChangeNotification, object: self)
    }

    // MARK: - Intercept keyboard operations

    open override func insertText(_ text: String) {
        
        // For some reason the text view is allowing the attachment style to be set in
        // typingAttributes.  That's simply not acceptable.
        //
        // This was causing the following issue:
        // https://github.com/wordpress-mobile/AztecEditor-iOS/issues/462
        //
        typingAttributes[.attachment] = nil

        guard !ensureRemovalOfParagraphAttributesWhenPressingEnterInAnEmptyParagraph(input: text) else {
            return
        }

        /// Whenever the user is at the end of the document, while editing a [List, Blockquote, Pre], we'll need
        /// to insert a `\n` character, so that the Layout Manager immediately renders the List's new bullet
        /// (or Blockquote's BG).
        ///
        ensureInsertionOfEndOfLine(beforeInserting: text)

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

        ensureCopyOfCodeCustomTypingAttributes(at: selectedRange)

        ensureCopyOfCiteCustomTypingAttributes(at: selectedRange)

        // WORKAROUND: iOS 11 introduced an issue that's causing UITextView to lose it's typing
        // attributes under certain circumstances.  The attributes are lost exactly after the call
        // to `super.insertText(text)`.  Our workaround is to simply save the typing attributes
        // and restore them after that call.
        //
        // Issue: https://github.com/wordpress-mobile/AztecEditor-iOS/issues/725
        //
        // Diego: I reproduced this issue in a very simple project (completely unrelated to Aztec)
        //      as a demonstration that this is an SDK issue.  I also reported this issue to
        //      Apple (34546954), but this workaround should do until the problem is resolved.
        //
        preserveTypingAttributesForInsertion {
            super.insertText(text)
        }

        evaluateRemovalOfSingleLineParagraphAttributesAfterSelectionChange()

        restoreDefaultFontIfNeeded()

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

        ensureRemovalOfParagraphStylesBeforeRemovingCharacter(at: selectedRange)

        preserveTypingAttributesForDeletion {
            super.deleteBackward()
        }

        evaluateRemovalOfSingleLineParagraphAttributesAfterSelectionChange()
        ensureRemovalOfParagraphAttributesWhenPressingBackspaceAndEmptyingTheDocument()
        ensureCursorRedraw(afterEditing: deletedString.string)

        notifyTextViewDidChange()
    }

    // MARK: - UIView Overrides

    open override func didMoveToWindow() {
        super.didMoveToWindow()
        layoutIfNeeded()
    }

    // MARK: - UITextView Overrides
    
    open override func caretRect(for position: UITextPosition) -> CGRect {
        var caretRect = super.caretRect(for: position)
        let characterIndex = offset(from: beginningOfDocument, to: position)
        
        guard layoutManager.isValidGlyphIndex(characterIndex) else {
            return caretRect
        }
        
        let glyphIndex = layoutManager.glyphIndexForCharacter(at: characterIndex)
        let usedLineFragment = layoutManager.lineFragmentUsedRect(forGlyphAt: glyphIndex, effectiveRange: nil)
        
        guard !usedLineFragment.isEmpty else {
            return caretRect
        }
     
        caretRect.origin.y = usedLineFragment.origin.y + textContainerInset.top
        caretRect.size.height = usedLineFragment.size.height

        return caretRect
    }
    
    /// When typing with the Chinese keyboard, the text is automatically marked in the editor.
    /// You have to press ENTER once to confirm your chosen input.  The problem is that in iOS 11
    /// the typing attributes are lost when the text is unmarked, causing the font to be lost.
    /// Since localized characters need specific fonts to be rendered, this causes some characters
    /// to stop rendering completely.
    ///
    /// Reference: https://github.com/wordpress-mobile/AztecEditor-iOS/issues/811
    ///
    override open func unmarkText() {
        preserveTypingAttributesForInsertion {
            super.unmarkText()
        }
    }

    // MARK: - HTML Interaction

    /// Converts the current Attributed Text into a raw HTML String
    ///
    /// - Returns: The HTML version of the current Attributed String.
    ///
    public func getHTML(prettify: Bool = true) -> String {
        return storage.getHTML(prettify: prettify)
    }

    /// Loads the specified HTML into the editor.
    ///
    /// - Parameter html: The raw HTML we'd be editing.
    ///
    public func setHTML(_ html: String) {
        // NOTE: there's a bug in UIKit that causes the textView's font to be changed under certain
        //      conditions.  We are assigning the default font here again to avoid that issue.
        //
        //      More information about the bug here:
        //          https://github.com/wordpress-mobile/WordPress-Aztec-iOS/issues/58
        //
        font = defaultFont
        
        storage.setHTML(html, defaultAttributes: defaultAttributes)

        if storage.length > 0 && selectedRange.location < storage.length {
            typingAttributes = storage.attributes(at: selectedRange.location, effectiveRange: nil)
        }

        notifyTextViewDidChange()
        formattingDelegate?.textViewCommandToggledAStyle()
    }
    
    public func replace(_ range: NSRange, withHTML html: String) {
        
        let string = storage.htmlConverter.attributedString(from: html, defaultAttributes: defaultAttributes)
        
        let originalString = storage.attributedSubstring(from: range)
        let finalRange = NSRange(location: range.location, length: string.length)
        
        undoManager?.registerUndo(withTarget: self, handler: { [weak self] target in
            self?.undoTextReplacement(of: originalString, finalRange: finalRange)
        })
        
        storage.replaceCharacters(in: range, with: string)
        selectedRange = NSRange(location: finalRange.location + finalRange.length, length: 0)
    }


    // MARK: - Attachment Helpers

    open func registerAttachmentImageProvider(_ provider: TextViewAttachmentImageProvider) {
        textAttachmentImageProvider.append(provider)
    }

    // MARK: - Getting format identifiers

    private static let formatterIdentifiersMap: [FormattingIdentifier: AttributeFormatter] = [
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
        .p: HTMLParagraphFormatter(),
        .code: CodeFormatter()
    ]

    /// Get a list of format identifiers spanning the specified range as a String array.
    ///
    /// - Parameter range: An NSRange to inspect.
    ///
    /// - Returns: A list of identifiers.
    ///
    open func formatIdentifiersSpanningRange(_ range: NSRange) -> Set<FormattingIdentifier> {
        guard storage.length != 0 else {
            return formatIdentifiersForTypingAttributes()
        }

        if range.length == 0 {
            return formatIdentifiersAtIndex(range.location)
        }

        var identifiers = Set<FormattingIdentifier>()

        for (key, formatter) in type(of: self).formatterIdentifiersMap {
            if formatter.present(in: storage, at: range) {
                identifiers.insert(key)
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
    open func formatIdentifiersAtIndex(_ index: Int) -> Set<FormattingIdentifier> {
        guard storage.length != 0 else {
            return []
        }

        let index = adjustedIndex(index)
        var identifiers = Set<FormattingIdentifier>()

        for (key, formatter) in type(of: self).formatterIdentifiersMap {
            if formatter.present(in: storage, at: index) {
                identifiers.insert(key)
            }
        }

        return identifiers
    }


    /// Get a list of format identifiers of the Typing Attributes.
    ///
    /// - Returns: A list of Formatting Identifiers.
    ///
    open func formatIdentifiersForTypingAttributes() -> Set<FormattingIdentifier> {
        let activeAttributes = typingAttributes
        var identifiers = Set<FormattingIdentifier>()

        for (key, formatter) in type(of: self).formatterIdentifiersMap where formatter.present(in: activeAttributes) {
            identifiers.insert(key)
        }

        return identifiers
    }

    // MARK: - UIResponderStandardEditActions

    open override func toggleBoldface(_ sender: Any?) {
        // We need to make sure our formatter is called.  We can't go ahead with the default
        // implementation.
        //
        toggleBold(range: selectedRange)

        formattingDelegate?.textViewCommandToggledAStyle()
    }

    open override func toggleItalics(_ sender: Any?) {
        // We need to make sure our formatter is called.  We can't go ahead with the default
        // implementation.
        //
        toggleItalic(range: selectedRange)

        formattingDelegate?.textViewCommandToggledAStyle()
    }

    open override func toggleUnderline(_ sender: Any?) {
        // We need to make sure our formatter is called.  We can't go ahead with the default
        // implementation.
        //
        toggleUnderline(range: selectedRange)

        formattingDelegate?.textViewCommandToggledAStyle()
    }

    // MARK: - Formatting

    func toggle(formatter: AttributeFormatter, atRange range: NSRange) {

        let applicationRange = formatter.applicationRange(for: range, in: textStorage)
        let originalString = storage.attributedSubstring(from: applicationRange)
        
        undoManager?.registerUndo(withTarget: self, handler: { [weak self] target in
            self?.undoTextReplacement(of: originalString, finalRange: applicationRange)
        })

        storage.toggle(formatter: formatter, at: range)

        if applicationRange.length == 0 {
            typingAttributes = formatter.toggle(in: typingAttributes)
        } else {
            // NOTE: We are making sure that the selectedRange location is inside the string
            // The selected range can be out of the string when you are adding content to the end of the string.
            // In those cases we check the atributes of the previous caracter
            let location = max(0,min(selectedRange.location, textStorage.length-1))
            typingAttributes = textStorage.attributes(at: location, effectiveRange: nil)
        }
        notifyTextViewDidChange()
    }

    func apply(formatter: AttributeFormatter, atRange range: NSRange, remove: Bool) {

        let applicationRange = formatter.applicationRange(for: range, in: textStorage)
        let originalString = storage.attributedSubstring(from: applicationRange)

        undoManager?.registerUndo(withTarget: self, handler: { [weak self] target in
            self?.undoTextReplacement(of: originalString, finalRange: applicationRange)
        })

        if remove {
            formatter.removeAttributes(from: storage, at: applicationRange)
        } else {
            formatter.applyAttributes(to: storage, at: applicationRange)
        }        

        if applicationRange.length == 0 {
            typingAttributes = formatter.toggle(in: typingAttributes)
        } else {
            // NOTE: We are making sure that the selectedRange location is inside the string
            // The selected range can be out of the string when you are adding content to the end of the string.
            // In those cases we check the atributes of the previous caracter
            let location = max(0,min(selectedRange.location, textStorage.length-1))
            typingAttributes = textStorage.attributes(at: location, effectiveRange: nil)
        }
        notifyTextViewDidChange()
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
        ensureInsertionOfEndOfLineForEmptyParagraphAtEndOfFile(forApplicationRange: range)

        let formatter = PreFormatter(placeholderAttributes: typingAttributes)
        toggle(formatter: formatter, atRange: range)

        forceRedrawCursorAfterDelay()
    }

    open func toggleCode(range: NSRange) {
        let formatter = CodeFormatter()
        formatter.placeholderAttributes = self.defaultAttributes
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
        ensureInsertionOfEndOfLineForEmptyParagraphAtEndOfFile(forApplicationRange: range)

        let formatter = BlockquoteFormatter(placeholderAttributes: typingAttributes)
        toggle(formatter: formatter, atRange: range)

        forceRedrawCursorAfterDelay()
    }

    /// Adds or removes a ordered list style from the specified range.
    ///
    /// - Parameter range: The NSRange to edit.
    ///
    open func toggleOrderedList(range: NSRange) {
        ensureInsertionOfEndOfLineForEmptyParagraphAtEndOfFile(forApplicationRange: range)

        let formatter = TextListFormatter(style: .ordered, placeholderAttributes: typingAttributes)
        toggle(formatter: formatter, atRange: range)

        let liFormatter = LiFormatter(placeholderAttributes: typingAttributes)
        toggle(formatter: liFormatter, atRange: range)

        forceRedrawCursorAfterDelay()
    }


    /// Adds or removes a unordered list style from the specified range.
    ///
    /// - Parameter range: The NSRange to edit.
    ///
    open func toggleUnorderedList(range: NSRange) {
        ensureInsertionOfEndOfLineForEmptyParagraphAtEndOfFile(forApplicationRange: range)

        let formatter = TextListFormatter(style: .unordered, placeholderAttributes: typingAttributes)
        toggle(formatter: formatter, atRange: range)

        let liFormatter = LiFormatter(placeholderAttributes: typingAttributes)
        toggle(formatter: liFormatter, atRange: range)
        
        forceRedrawCursorAfterDelay()
    }


    /// Adds or removes a unordered list style from the specified range.
    ///
    /// - Parameter range: The NSRange to edit.
    ///
    open func toggleHeader(_ headerType: Header.HeaderType, range: NSRange) {
        let formatter = HeaderFormatter(headerLevel: headerType, placeholderAttributes: typingAttributes)
        toggle(formatter: formatter, atRange: range)
        forceRedrawCursorAfterDelay()
    }

    /// Replaces with an horizontal ruler on the specified range
    ///
    /// - Parameter range: the range where the ruler will be inserted
    ///
    open func replaceWithHorizontalRuler(at range: NSRange) {
        let line = LineAttachment()
        replace(at: range, with: line)
    }

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

    /// Verifies if the Active Font's Family Name matches with our Default Font, or not. If the family diverges,
    /// this helper will proceed to restore the defaultFont's Typing Attributes
    /// This is meant as a workaround for the "Emojis Mixing Up Font's" glitch.
    ///
    private func restoreDefaultFontIfNeeded() {
        guard let activeFont = typingAttributes[.font] as? UIFont, activeFont.isAppleEmojiFont else {
            return
        }

        typingAttributes[.font] = defaultFont.withSize(activeFont.pointSize)
    }


    /// Inserts an end-of-line character whenever the provided range is at end-of-file, in an
    /// empty paragraph. This is useful when attempting to apply a paragraph-level style at EOF,
    /// since it won't be possible without the paragraph having any characters.
    ///
    /// Call this method before applying the formatter.
    ///
    /// - Parameters:
    ///     - range: the range where the formatter will be applied.
    ///
    private func ensureInsertionOfEndOfLineForEmptyParagraphAtEndOfFile(forApplicationRange range: NSRange) {

        guard let selectedRangeForSwift = textStorage.string.nsRange(fromUTF16NSRange: range) else {
            assertionFailure("This should never happen.  Review the logic!")
            return
        }

        if selectedRangeForSwift.location == textStorage.length
            && textStorage.string.isEmptyLine(at: selectedRangeForSwift.location) {

            insertEndOfLineCharacter()
        }
    }

    /// Inserts an end-of-line chracter whenever:
    ///
    ///     A.  We're about to insert a new line
    ///     B.  We're at the end of the document
    ///     C.  There's a List (OR) Blockquote (OR) Pre active
    ///
    /// We're doing this as a workaround, in order to force the LayoutManager render the Bullet (OR) 
    /// Blockquote's background.
    ///
    private func ensureInsertionOfEndOfLine(beforeInserting text: String) {

        guard text.isEndOfLine(),
            selectedRange.location == storage.length else {
                return
        }

        let formatters: [AttributeFormatter] = [
            BlockquoteFormatter(),
            PreFormatter(placeholderAttributes: self.defaultAttributes),
            TextListFormatter(style: .ordered),
            TextListFormatter(style: .unordered)
        ]

        let activeTypingAttributes = typingAttributes
        let found = formatters.first { formatter in
            return formatter.present(in: activeTypingAttributes)
        }

        guard found != nil else {
            return
        }

        insertEndOfLineCharacter()
    }

    /// Inserts a end-of-line character at the current position, while retaining the selectedRange
    /// and typingAttributes.
    ///
    private func insertEndOfLineCharacter() {
        let previousRange = selectedRange
        let previousStyle = convertFromNSAttributedStringKeyDictionary(typingAttributes)

        super.insertText(String(.paragraphSeparator))

        selectedRange = previousRange
        typingAttributes = convertToNSAttributedStringKeyDictionary(previousStyle)
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
        guard typingAttributes[.link] != nil else {
            return
        }

        guard !storage.isLocationPreceededByLink(range.location) ||
            !storage.isLocationSuccededByLink(range.location)
            else {
                return
        }

        typingAttributes.removeValue(forKey: .link)
    }

    /// This method makes sure that the Custom Code HTML attribute is copy across to the next character that is typed on the textview.
    ///
    /// - Parameter range: the range where the new text will be inserted
    ///
    private func ensureCopyOfCodeCustomTypingAttributes(at range: NSRange) {
        guard typingAttributes[.codeHtmlRepresentation] == nil,
            storage.isLocation(range.location, preceededBy: .codeHtmlRepresentation) else {
            return
        }

        typingAttributes[.codeHtmlRepresentation] = HTMLRepresentation(for: .element(HTMLElementRepresentation.init(name: "code", attributes: [])))
    }

    /// This method makes sure that the Custom Code HTML attribute is copy across to the next character that is typed on the textview.
    ///
    /// - Parameter range: the range where the new text will be inserted
    ///
    private func ensureCopyOfCiteCustomTypingAttributes(at range: NSRange) {
        guard typingAttributes[.citeHtmlRepresentation] == nil,
            storage.isLocation(range.location, preceededBy: .citeHtmlRepresentation) else {
                return
        }

        typingAttributes[.citeHtmlRepresentation] = HTMLRepresentation(for: .element(HTMLElementRepresentation.init(name: "cite", attributes: [])))
    }


    /// Force the SDK to Redraw the cursor, asynchronously, if the edited text (inserted / deleted) requires it.
    /// This method was meant as a workaround for Issue #144.
    ///
    func ensureCursorRedraw(afterEditing text: String) {
        guard text == String(.lineFeed) else {
            return
        }

        forceRedrawCursorAfterDelay()
    }


    /// Force the SDK to Redraw the cursor, asynchronously, after a delay. This method was meant as a workaround
    /// for Issue #144: the Caret might end up redrawn below the Blockquote's custom background.
    ///
    /// Workaround: By changing the selectedRange back and forth, we're forcing UITextView to effectively re-render
    /// the caret.
    ///
    func forceRedrawCursorAfterDelay() {
        let delay = 0.05
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            let pristine = self.selectedRange
            let maxLength = self.storage.length

            // Determine the Temporary Shift Location:
            // - If we're at the end of the document, we'll move the caret minus one character
            // - Otherwise, we'll move the caret plus one position
            //
            let delta = pristine.location == maxLength ? -1 : 1
            let location = min(max(pristine.location + delta, 0), maxLength)

            // Yes. This is a Workaround on top of another workaround.
            // WARNING: The universe may fade out of existance.
            //
            self.preserveTypingAttributesForInsertion {

                // Shift the SelectedRange to a nearby position: *FORCE* cursor redraw
                //
                self.selectedRange = NSMakeRange(location, 0)

                // Finally, restore the original SelectedRange and the typingAttributes we had before beginning
                //
                self.selectedRange = pristine
            }
        }
    }
    
    // MARK: - iOS 11 Workarounds
    
    /// This method fixes an issue that was introduced in iOS 11.  Styles were lost when you selected an autocomplete
    /// suggestion.
    ///
    ///
    ///
    /// How to remove: if you disable this method and notice that autocomplete suggestions are not losing styles when
    /// selected, feel free to remove it.
    ///
    /// This bug affected at least the range of iOS versions fromS 11.0 to 11.0.3 (both included).
    ///
    @objc func replaceRangeWithTextWithoutClosingTyping(_ range: UITextRange, replacementText: String) {
        
        // We're only wrapping the call to super in `preserveTypingAttributesForInsertion` to make sure
        // that the style is not lost due to an iOS 11 issue.
        //
        preserveTypingAttributesForInsertion{ [weak self] in
            guard let `self` = self else {
                return
            }

            // From here on, it's just calling the same method in `super`.
            //
            let selector = #selector(TextView.replaceRangeWithTextWithoutClosingTyping(_:replacementText:))
            let imp = class_getMethodImplementation(TextView.superclass(), selector)

            typealias ClosureType = @convention(c) (AnyObject, Selector, UITextRange, String) -> Void
            let superMethod: ClosureType = unsafeBitCast(imp, to: ClosureType.self)
            let currentAttributes = self.typingAttributes
            superMethod(self, selector, range, replacementText)
            // apply all attributes that where set before the call to the new text
            self.textStorage.setAttributes(currentAttributes, range: adjustedRangeFrom(uiTextRange: range, replacedBy: replacementText))
        }
    }

    func adjustedRangeFrom(uiTextRange range: UITextRange, replacedBy text: String) -> NSRange {
        let location = offset(from: beginningOfDocument, to: range.start)
        let length = (text as NSString).length

        return NSRange(location: location, length: length)
    }

    /// Workaround: This method preserves the Typing Attributes, and prevents the UITextView's delegate from beign
    /// called during the `block` execution.
    ///
    /// We're implementing this because of a bug in iOS 11, in which Typing Attributes are being lost by methods such as:
    ///
    ///     -   `deleteBackwards`
    ///     -   `insertText`
    ///     -   Autocompletion!
    ///
    /// Reference: https://github.com/wordpress-mobile/AztecEditor-iOS/issues/748
    ///
    private func preserveTypingAttributesForInsertion(block: () -> Void) {
        
        // We really don't want this code running below iOS 10.
        guard #available(iOS 11, *) else {
            block()
            return
        }
        
        let beforeTypingAttributes = convertFromNSAttributedStringKeyDictionary(typingAttributes)
        let beforeDelegate = delegate

        delegate = nil
        block()

        typingAttributes = convertToNSAttributedStringKeyDictionary(beforeTypingAttributes)
        delegate = beforeDelegate

        // Manually notify the delegates: We're avoiding overwork!
        delegate?.textViewDidChangeSelection?(self)
        notifyTextViewDidChange()
    }

    /// WORKAROUND: iOS 11 introduced an issue that's causing UITextView to lose it's typing
    /// attributes under certain circumstances. This method will determine the Typing Attributes based on
    /// the TextStorage attributes, whenever possible.
    ///
    /// Issue: https://github.com/wordpress-mobile/AztecEditor-iOS/issues/749
    ///
    private func preserveTypingAttributesForDeletion(block: () -> Void) {
        
        // We really don't want this code running below iOS 10.
        guard #available(iOS 11, *) else {
            block()
            return
        }
        
        let document = textStorage.string
        guard selectedRange.location == document.count, document.count > 0 else {
            block()
            return
        }

        let previousLocation = max(selectedRange.location - 1, 0)
        let previousAttributes = textStorage.attributes(at: previousLocation, effectiveRange: nil)

        block()

        typingAttributes = previousAttributes
    }


    // MARK: - Links

    /// Adds a link to the designated url on the specified range.
    ///
    /// - Parameters:
    ///     - url: the NSURL to link to.
    ///     - title: the text for the link.
    ///     - target: the target for the link
    ///     - range: The NSRange to edit.
    ///
    open func setLink(_ url: URL, title: String, target: String? = nil, inRange range: NSRange) {

        let originalText = attributedText.attributedSubstring(from: range)
        let attributedTitle = NSAttributedString(string: title)
        let finalRange = NSRange(location: range.location, length: attributedTitle.length)        

        undoManager?.registerUndo(withTarget: self, handler: { [weak self] target in
            self?.undoTextReplacement(of: originalText, finalRange: finalRange)
        })

        let formatter = LinkFormatter(target: target)
        formatter.attributeValue = url

        let attributes = formatter.apply(to: typingAttributes)
        storage.replaceCharacters(in: range, with: NSAttributedString(string: title, attributes: attributes))

        selectedRange = NSRange(location: finalRange.location + finalRange.length, length: 0)

        notifyTextViewDidChange()
    }

    /// Adds a link to the designated url on the specified range.
    ///
    /// - Parameters:
    ///     - url: the NSURL to link to.
    ///     - target: the target for the link
    ///     - range: The NSRange to edit.
    ///
    open func setLink(_ url: URL, target: String? = nil, inRange range: NSRange) {
        let formatter = LinkFormatter(target: target)
        formatter.attributeValue = url

        apply(formatter: formatter, atRange: range, remove: false)
    }

    /// Removes the link, if any, at the specified range
    ///
    /// - Parameter range: range that contains the link to be removed.
    ///
    open func removeLink(inRange range: NSRange) {
        let formatter = LinkFormatter()
        apply(formatter: formatter, atRange: range, remove: true)
    }


    // MARK: - Embeds

    func replace(at range: NSRange, with attachment: NSTextAttachment) {
        let originalText = textStorage.attributedSubstring(from: range)
        let finalRange = NSRange(location: range.location, length: NSAttributedString.lengthOfTextAttachment)

        undoManager?.registerUndo(withTarget: self, handler: { [weak self] target in
            self?.undoTextReplacement(of: originalText, finalRange: finalRange)
        })

        let attachmentString = NSAttributedString(attachment: attachment, attributes: typingAttributes)
        storage.replaceCharacters(in: range, with: attachmentString)
        selectedRange = NSMakeRange(range.location + NSAttributedString.lengthOfTextAttachment, 0)
        notifyTextViewDidChange()
    }

    /// Replaces with an image attachment at the specified range
    ///
    /// - Parameters:
    ///     - range: the range where the image will be inserted
    ///     - sourceURL: The url of the image to be inserted.
    ///     - placeHolderImage: the image to be used as an placeholder.
    ///     - identifier: an unique identifier for the image
    ///
    /// - Returns: the attachment object that can be used for further calls
    ///
    @discardableResult
    open func replaceWithImage(at range: NSRange, sourceURL url: URL, placeHolderImage: UIImage?, identifier: String = UUID().uuidString) -> ImageAttachment {
        let attachment = ImageAttachment(identifier: identifier, url: url)
        attachment.delegate = storage
        attachment.image = placeHolderImage
        attachment.alignment = .none
        replace(at: range, with: attachment)
        return attachment
    }


    /// Returns the MediaAttachment instance with the matching identifier
    ///
    /// - Parameter id: Identifier of the text attachment to be retrieved
    ///
    open func attachment(withId id: String) -> MediaAttachment? {
        return storage.attachment(withId: id)
    }

    /// Removes the attachment that matches the attachment identifier provided from the storage
    ///
    /// - Parameter attachmentID: the unique id of the attachment
    ///
    open func remove(attachmentID: String) {
        guard let range = storage.rangeFor(attachmentID: attachmentID) else {
            return
        }
        let originalText = storage.attributedSubstring(from: range)
        let finalRange = NSRange(location: range.location, length: 0)

        undoManager?.registerUndo(withTarget: self, handler: { [weak self] target in
            self?.undoTextReplacement(of: originalText, finalRange: finalRange)
        })

        storage.replaceCharacters(in: range, with: NSAttributedString(string: "", attributes: typingAttributes))
        notifyTextViewDidChange()
    }

    /// Removes all of the text attachments contained within the storage
    ///
    open func removeMediaAttachments() {
        storage.removeMediaAttachments()
        notifyTextViewDidChange()
    }

    /// Replaces a Video attachment at the specified range
    ///
    /// - Parameters:
    ///   - range: the range in the text to insert the video
    ///   - sourceURL: the video source URL
    ///   - posterURL: the video poster image URL
    ///   - placeHolderImage: an image to use has an placeholder while the video poster is being loaded
    ///   - identifier: an unique indentifier for the video
    ///
    /// - Returns: the video attachment object that was inserted.
    ///
    @discardableResult
    open func replaceWithVideo(at range: NSRange, sourceURL: URL, posterURL: URL?, placeHolderImage: UIImage?, identifier: String = UUID().uuidString) -> VideoAttachment {
        let attachment = VideoAttachment(identifier: identifier, srcURL: sourceURL, posterURL: posterURL)
        attachment.delegate = storage
        attachment.image = placeHolderImage
        replace(at: range, with: attachment)
        return attachment
    }

    /// Returns the associated NSTextAttachment, at a given point, if any.
    ///
    /// - Parameter point: The point on screen to check for attachments.
    ///
    /// - Returns: The associated NSTextAttachment.
    ///
    open func attachmentAtPoint(_ point: CGPoint) -> NSTextAttachment? {
        let index = layoutManager.characterIndex(for: point, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        guard index < textStorage.length else {
            return nil
        }

        var effectiveRange = NSRange()
        guard let attachment = textStorage.attribute(.attachment, at: index, effectiveRange: &effectiveRange) as? NSTextAttachment else {
            return nil
        }

        var bounds = layoutManager.boundingRect(forGlyphRange: effectiveRange, in: textContainer)
        bounds.origin.x += textContainerInset.left
        bounds.origin.y += textContainerInset.top

        // Let's check if we have media attachment in place
        guard let mediaAttachment = attachment as? MediaAttachment else {
            return bounds.contains(point) ? attachment : nil
        }

        // Correct the bounds taking in account the dimesion of the media image being used
        let mediaBounds = mediaAttachment.imageBounds(for: bounds)

        bounds.origin.x += mediaBounds.origin.x
        bounds.origin.y += mediaBounds.origin.y
        bounds.size.width = mediaBounds.size.width
        bounds.size.height = mediaBounds.size.height

        return bounds.contains(point) ? attachment : nil
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


    /// Check if there is an attachment at the location we are moving. If there is one check if we want to move before or after the
    /// attachment based on the margins.
    ///
    /// - Parameter point: the point to check.
    /// - Returns: true if the point fall inside an attachment margin
    ///
    open func isPointInsideAttachmentMargin(point: CGPoint) -> Bool {
        let index = layoutManager.characterIndex(for: point, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)

        if let attachment = attachmentAtPoint(point) as? MediaAttachment {
            let glyphRange = layoutManager.glyphRange(forCharacterRange: NSRange(location: index, length: 1), actualCharacterRange: nil)
            let rect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
            let imageInsets = attachment.appearance.imageInsets

            if point.y >= rect.origin.y && point.y <= (rect.origin.y + (imageInsets.top + imageInsets.bottom)) {
                return true
            }
        }
        return false
    }

    // MARK: - Links

    open func linkInfo(for attachment: NSTextAttachment) -> (range: NSRange, url: URL)? {
        guard let attachmentRange = textStorage.ranges(forAttachment: attachment).first,
            let linkFullRange = self.linkFullRange(forRange: attachmentRange),
            let linkURL = self.linkURL(for: attachment)  else {
                return nil
        }

        return (linkFullRange, linkURL)
    }
    
    open func linkURL(for attachment: NSTextAttachment) -> URL? {
        guard let attachmentRange = textStorage.ranges(forAttachment: attachment).first else {
            return nil
        }
        
        return linkURL(forRange: attachmentRange)
    }
    
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
            let attr = storage.attribute(.link, at: index, effectiveRange: &effectiveRange)
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

    /// Returns the link target value if the specified range has attached a link attribute
    ///
    /// - Parameter range: The NSRange to inspect
    ///
    /// - Returns: The target if available
    ///
    open func linkTarget(forRange range: NSRange) -> String? {
        let index = maxIndex(range.location)
        var effectiveRange = NSRange()
        guard index < storage.length,
            let _ = storage.attribute(.link, at: index, longestEffectiveRange: &effectiveRange, in: storage.rangeOfEntireString),        
            let representation = storage.attribute(.linkHtmlRepresentation, at: effectiveRange.location, effectiveRange: nil) as? HTMLRepresentation,
            case .element(let element) = representation.kind
            else {
                return nil
        }

        if let target = element.attribute(named: HTMLLinkAttribute.target.rawValue)?.value.toString() {
            return target
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
            storage.attribute(.link, at: index, longestEffectiveRange: &effectiveRange, in: NSMakeRange(0, storage.length)) != nil
            else {
                return nil
        }

        return effectiveRange
    }
    
    // MARK: - Captions

    open func caption(for attachment: NSTextAttachment) -> NSAttributedString? {
        return textStorage.caption(for: attachment)
    }
    
    open func removeCaption(for attachment: NSTextAttachment) {
        guard let attachmentRange = textStorage.ranges(forAttachment: attachment).first,
            let captionRange = textStorage.captionRange(for: attachment) else {
                return
        }
        
        let finalRange = NSRange(location: attachmentRange.location, length: attachmentRange.length + captionRange.length)
        
        textStorage.replaceCharacters(in: finalRange, with: NSAttributedString(attachment: attachment))
        
        notifyTextViewDidChange()
    }
    
    open func replaceCaption(for attachment: NSTextAttachment, with newCaption: NSAttributedString) {
        guard let attachmentRange = textStorage.ranges(forAttachment: attachment).first else {
            return
        }
        
        guard let existingCaptionRange = textStorage.captionRange(for: attachment) else {
            let newAttachmentString = NSAttributedString(attachment: attachment, caption: newCaption, attributes: [:])
            textStorage.replaceCharacters(in: attachmentRange, with: newAttachmentString)

            return
        }

        // We maintain the original paragraph style since this is really not intended to be editable.  It also maintains
        // the original Figure and Figcaption objects.
        let originalParagraphStyle = textStorage.attribute(.paragraphStyle, at: existingCaptionRange.location, effectiveRange: nil) as! ParagraphStyle
        var newAttributes = newCaption.attributes(at: 0, effectiveRange: nil)
        newAttributes[.paragraphStyle] = originalParagraphStyle
        
        // TODO: when the caption is not there, we must insert it (and format the attachment as a FIGURE())
        
        let finalCaption = NSMutableAttributedString()
        
        finalCaption.append(newCaption)
        finalCaption.append(NSAttributedString(.paragraphSeparator, attributes: [:]))
        finalCaption.setAttributes(newAttributes, range: finalCaption.rangeOfEntireString)
        
        textStorage.replaceCharacters(in: existingCaptionRange, with: finalCaption)
        
        notifyTextViewDidChange()
    }
 
    // MARK: - Storage Indexes (WTF?)


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

    /// Invalidates the layout of the attachment and marks it to be refresh on the next update cycle.
    /// This method should be called after editing any kind of *Attachment, since, whenever its bounds
    /// do change, we'll need to perform a layout pass. Otherwise, TextKit's inner map won't match with
    /// what's actually onscreen.
    ///
    /// - Parameters:
    ///   - attachment: the attachment to update
    ///   - overlayUpdateOnly: when this arguments is true, the attachment is only marked to refresh it's display, witthout the need to relayout. This should only be used when changes done to the attachment don't affect it's previous dimensions.
    ///
    open func refresh(_ attachment: NSTextAttachment, overlayUpdateOnly: Bool = false) {
        guard let range = storage.range(for: attachment) else {
            return
        }
        if overlayUpdateOnly {
            layoutManager.invalidateDisplay(forCharacterRange: range)
        } else {
            storage.edited(.editedAttributes, range: range, changeInLength: 0)
        }
    }

    /// Helper that allows us to Edit a NSTextAttachment instance, with two extras:
    ///
    /// - Undo Support comes for free!
    /// - Layout will be ensured right after executing the edition block
    ///
    /// - Parameters:
    ///     - attachment: Instance to be edited
    ///     - block: Edition closure to be executed
    ///
    /// - Returns: a copy of the original attachment for undoing purposes.
    ///
    @discardableResult
    open func edit<T>(_ attachment: T, block: (T) -> ()) -> T where T:NSTextAttachment {

        precondition(storage.range(for: attachment) != nil)

        // Don't call this method if the attachment is not in the text view.
        let range = storage.range(for: attachment)!

        // This should NEVER fail because the copy should not change type.
        let copy = attachment.copy() as! T

        block(copy)

        performUndoable(at: range) {
            var originalAttributes = storage.attributes(at: range.location, effectiveRange: nil)
            originalAttributes[.attachment] = copy
            
            storage.setAttributes(originalAttributes, range: range)
            return range
        }
        
        notifyTextViewDidChange()
    
        return copy
    }


    // MARK: - More

    /// Replaces a range with a comment.
    ///
    /// - Parameters:
    ///     - range: The character range that must be replaced with a Comment Attachment.
    ///     - comment: The text for the comment.
    ///
    /// - Returns: the attachment object that can be used for further calls
    ///
    @discardableResult
    open func replace(_ range: NSRange, withComment comment: String) -> CommentAttachment {
        let attachment = CommentAttachment()
        attachment.text = comment
        replace(at: range, with: attachment)

        return attachment
    }
}

// MARK: - Single line attributes removal
//
private extension TextView {

    // MARK: - WORKAROUND: Removing paragraph styles after deleting the last character in the current line.

    /// Ensures Paragraph Styles are removed, if needed, *before* a character gets removed from the storage,
    /// at the specified range.
    ///
    /// - Parameter range: Range at which a character is about to be removed.
    ///
    func ensureRemovalOfParagraphStylesBeforeRemovingCharacter(at range: NSRange) {
        guard mustRemoveParagraphStylesBeforeRemovingCharacter(at: range) else {
            return
        }

        removeParagraphAttributes(at: range)
    }

    /// Analyzes whether the attributes should be removed from the specified location, *before* removing a 
    /// character at the specified location.
    ///
    /// - Parameter range: Range at which we'll remove a character
    ///
    /// - Returns: `true` if we should nuke the paragraph attributes.
    ///
    private func mustRemoveParagraphStylesBeforeRemovingCharacter(at range: NSRange) -> Bool {
        return storage.string.isEmptyParagraph(at: range.location)
    }

    // MARK: - Single-line attributes logic.
    
    private func evaluateRemovalOfSingleLineParagraphAttributesAfterSelectionChange() {
        guard storage.string.isEmptyParagraph(at: selectedRange.location) else {
            return
        }
        
        removeSingleLineParagraphAttributes()
    }

    /// Removes single-line paragraph attributes.
    ///
    private func removeSingleLineParagraphAttributes() {
        for formatter in type(of: self).singleLineParagraphFormatters {
            let range = formatter.applicationRange(for: selectedRange, in: textStorage)
            
            removeAttributes(managedBy: formatter, from: range)
            removeTypingAttributes(managedBy: formatter)
        }
    }
    
    // MARK: - Attributes
    
    private func removeAttributes(managedBy formatter: AttributeFormatter, from range: NSRange) {
        let applicationRange = formatter.applicationRange(for: selectedRange, in: textStorage)
        formatter.removeAttributes(from: textStorage, at: applicationRange)
    }
    
    private func removeTypingAttributes(managedBy formatter: AttributeFormatter) {
        typingAttributes = formatter.remove(from: typingAttributes)
    }

    // MARK: - WORKAROUND: Removing paragraph styles when pressing enter in an empty paragraph

    /// Removes paragraph attributes after pressing enter in an empty paragraph.
    ///
    /// - Parameter input: the user's input.  This method must be called before the input is processed.
    ///
    func ensureRemovalOfParagraphAttributesWhenPressingEnterInAnEmptyParagraph(input: String) -> Bool {
        guard mustRemoveParagraphAttributesWhenPressingEnterInAnEmptyParagraph(input: input) else {
            return false
        }

        removeParagraphAttributes(at: selectedRange)

        return true
    }

    /// Analyzes whether paragraph attributes should be removed after pressing enter in an empty
    /// paragraph.
    ///
    /// - Returns: `true` if we should remove paragraph attributes, otherwise it returns `false`.
    ///
    private func mustRemoveParagraphAttributesWhenPressingEnterInAnEmptyParagraph(input: String) -> Bool {
        let activeTypingAttributes = typingAttributes

        return input.isEndOfLine()
            && storage.string.isEmptyLine(at: selectedRange.location)
            && (BlockquoteFormatter().present(in: activeTypingAttributes)
                || TextListFormatter.listsOfAnyKindPresent(in: activeTypingAttributes)
                || PreFormatter().present(in: activeTypingAttributes))
    }


    // MARK: - WORKAROUND: Removing paragraph styles when pressing backspace and removing the last character

    /// Removes paragraph attributes after pressing backspace, if the resulting document is empty.
    ///
    func ensureRemovalOfParagraphAttributesWhenPressingBackspaceAndEmptyingTheDocument() {
        guard mustRemoveParagraphAttributesWhenPressingBackspaceAndEmptyingTheDocument() else {
            return
        }

        removeParagraphAttributes(at: selectedRange)
    }

    /// Analyzes whether paragraph attributes should be removed from the specified
    /// location, or not, after pressing backspace.
    ///
    /// - Returns: `true` if we should remove paragraph attributes, otherwise it returns `false`.
    ///
    private func mustRemoveParagraphAttributesWhenPressingBackspaceAndEmptyingTheDocument() -> Bool {
        return storage.length == 0
    }

    // MARK: - WORKAROUND: Removing styles at EOF due to selection change

    /// Removes paragraph attributes after a selection change.
    ///
    func ensureRemovalOfParagraphAttributesAfterSelectionChange() {
        guard mustRemoveParagraphAttributesAfterSelectionChange() else {
            return
        }

        removeParagraphAttributes(at: selectedRange)
    }

    /// Analyzes whether paragraph attributes should be removed from the specified
    /// location, or not, after the selection range is changed.
    ///
    /// - Returns: `true` if we should remove paragraph attributes, otherwise it returns `false`.
    ///
    private func mustRemoveParagraphAttributesAfterSelectionChange() -> Bool {
        return selectedRange.location == storage.length
            && storage.string.isEmptyParagraph(at: selectedRange.location)
            && markedTextRange == nil
    }

    /// Removes the Paragraph Attributes [Blockquote, Pre, Lists] at the specified range. If the range
    /// is beyond the storage's contents, the typingAttributes will be modified.
    ///
    private func removeParagraphAttributes(at range: NSRange) {
        let formatters: [AttributeFormatter] = [
            BlockquoteFormatter(),
            PreFormatter(placeholderAttributes: defaultAttributes),
            TextListFormatter(style: .ordered),
            TextListFormatter(style: .unordered)
        ]

        for formatter in formatters {
            let activeTypingAttributes = super.typingAttributes
            guard formatter.present(in: activeTypingAttributes) else {
                continue
            }

            let updatedTypingAttributes = formatter.remove(from: activeTypingAttributes)
            super.typingAttributes = updatedTypingAttributes

            let applicationRange = formatter.applicationRange(for: selectedRange, in: textStorage)
            formatter.removeAttributes(from: textStorage, at: applicationRange)
        }
    }
}


// MARK: - TextStorageImageProvider
//
extension TextView: TextStorageAttachmentsDelegate {

    func storage(
        _ storage: TextStorage,
        attachment: NSTextAttachment,
        imageFor url: URL,
        onSuccess success: @escaping (UIImage) -> (),
        onFailure failure: @escaping () -> ()) {
        
        guard let textAttachmentDelegate = textAttachmentDelegate else {
            fatalError("This class requires a text attachment delegate to be set.")
        }
        
        textAttachmentDelegate.textView(self, attachment: attachment, imageAt: url, onSuccess: success, onFailure: failure)
    }

    func storage(_ storage: TextStorage, placeholderFor attachment: NSTextAttachment) -> UIImage {
        guard let textAttachmentDelegate = textAttachmentDelegate else {
            fatalError("This class requires a text attachment delegate to be set.")
        }

        return textAttachmentDelegate.textView(self, placeholderFor: attachment)
    }
    
    func storage(_ storage: TextStorage, urlFor imageAttachment: ImageAttachment) -> URL? {
        guard let textAttachmentDelegate = textAttachmentDelegate else {
            fatalError("This class requires a text attachment delegate to be set.")
        }
        
        return textAttachmentDelegate.textView(self, urlFor: imageAttachment)
    }

    func storage(_ storage: TextStorage, deletedAttachment attachment: MediaAttachment) {
        textAttachmentDelegate?.textView(self, deletedAttachment: attachment)
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
@objc class AttachmentGestureRecognizerDelegate: NSObject, UIGestureRecognizerDelegate {

    private weak var textView: TextView?
    fileprivate var currentSelectedAttachment: MediaAttachment?

    public init(textView: TextView) {
        self.textView = textView
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard let textView = textView else {
            return false
        }

        let locationInTextView = touch.location(in: textView)
        let isAttachmentInLocation = textView.attachmentAtPoint(locationInTextView) != nil
        if !isAttachmentInLocation {
            if let selectedAttachment = currentSelectedAttachment {
                textView.textAttachmentDelegate?.textView(textView, deselected: selectedAttachment, atPosition: locationInTextView)
            }
            currentSelectedAttachment = nil
        }
        return isAttachmentInLocation

    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let textView = textView else {
            return false
        }

        let locationInTextView = gestureRecognizer.location(in: textView)
        guard textView.attachmentAtPoint(locationInTextView) != nil else {
            if let selectedAttachment = currentSelectedAttachment {
                textView.textAttachmentDelegate?.textView(textView, deselected: selectedAttachment, atPosition: locationInTextView)
            }
            currentSelectedAttachment = nil
            return false
        }
        return true
    }

    @objc func richTextViewWasPressed(_ recognizer: UIGestureRecognizer) {
        guard let textView = textView, recognizer.state == .recognized else {
            return
        }

        let locationInTextView = recognizer.location(in: textView)
        guard let attachment = textView.attachmentAtPoint(locationInTextView) else {
            return
        }

        textView.moveSelectionToPoint(locationInTextView)

        if textView.isPointInsideAttachmentMargin(point: locationInTextView) {
            if let selectedAttachment = currentSelectedAttachment {
                textView.textAttachmentDelegate?.textView(textView, deselected: selectedAttachment, atPosition: locationInTextView)
            }
            currentSelectedAttachment = nil
            return
        }

        currentSelectedAttachment = attachment as? MediaAttachment
        textView.textAttachmentDelegate?.textView(textView, selected: attachment, atPosition: locationInTextView)
    }
}


// MARK: - Undo implementation
//
private extension TextView {

    /// Undoable Operation. Returns the Final Text Range, resulting from applying the undoable Operation
    /// Note that for Styling Operations, the Final Range will most likely match the Initial Range.
    /// For text editing it will only match the initial range if the original string was replaced with a 
    /// string of the same length.
    ///
    typealias Undoable = () -> NSRange


    /// Registers an Undoable Operation, which will be applied at the specified Initial Range.
    ///
    /// - Parameters:
    ///     - initialRange: Initial Storage Range upon which we'll apply a transformation.
    ///     - block: Undoable Operation. Should return the resulting Substring's Range.
    ///
    func performUndoable(at initialRange: NSRange, block: Undoable) {
        let originalString = storage.attributedSubstring(from: initialRange)

        let finalRange = block()

        undoManager?.registerUndo(withTarget: self, handler: { [weak self] target in
            self?.undoTextReplacement(of: originalString, finalRange: finalRange)
        })

        notifyTextViewDidChange()
    }

    func undoTextReplacement(of originalText: NSAttributedString, finalRange: NSRange) {

        let redoFinalRange = NSRange(location: finalRange.location, length: originalText.length)
        let redoOriginalText = storage.attributedSubstring(from: finalRange)

        storage.replaceCharacters(in: finalRange, with: originalText)
        selectedRange = redoFinalRange

        undoManager?.registerUndo(withTarget: self, handler: { [weak self] target in
            self?.undoTextReplacement(of: redoOriginalText, finalRange: redoFinalRange)
        })

        notifyTextViewDidChange()
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromNSAttributedStringKeyDictionary(_ input: [NSAttributedString.Key: Any]) -> [String: Any] {
	return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToNSAttributedStringKeyDictionary(_ input: [String: Any]) -> [NSAttributedString.Key: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromOptionalNSAttributedStringKeyDictionary(_ input: [NSAttributedString.Key: Any]?) -> [String: Any]? {
	guard let input = input else { return nil }
	return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
	guard let input = input else { return nil }
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value)})
}
