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

    private(set) lazy var attachmentManager: AztecAttachmentManager = {
        AztecAttachmentManager(textView: self)
    }()

    /// The media delegate takes care of providing remote media when requested by the `TextView`.
    /// If this is not set, all remove images will be left blank.
    ///
    public weak var mediaDelegate: TextViewMediaDelegate? = nil

    // MARK: - Properties: GUI Defaults

    let defaultFont: UIFont
    var defaultMissingImage: UIImage

    // MARK: - Properties: Text Storage

    var storage: AztecTextStorage {
        return textStorage as! AztecTextStorage
    }

    // MARK: - Properties: UIView Overrides

    override public var bounds: CGRect {
        didSet {
            if oldValue.size == bounds.size {
                return
            }

            attachmentManager.resizeAttachments()
        }
    }

    // MARK: - Init & deinit

    public init(defaultFont: UIFont, defaultMissingImage: UIImage) {
        let storage = AztecTextStorage()
        let layoutManager = NSLayoutManager()
        let container = NSTextContainer()

        self.defaultFont = defaultFont
        self.defaultMissingImage = defaultMissingImage

        storage.addLayoutManager(layoutManager)
        layoutManager.addTextContainer(container)
        container.widthTracksTextView = true

        super.init(frame: CGRect(x: 0, y: 0, width: 10, height: 10), textContainer: container)

        startListeningToEvents()
    }

    required public init?(coder aDecoder: NSCoder) {

        defaultFont = UIFont.systemFontOfSize(14)
        defaultMissingImage = Gridicon.iconOfType(.Image)

        super.init(coder: aDecoder)
    }

    deinit {
        stopListeningToEvents()
    }


    // MARK: - UIView Overrides

    public override func didMoveToWindow() {
        super.didMoveToWindow()
        attachmentManager.layoutAttachmentViews()
    }


    // MARK: - Events

    /// Wires all of the Notifications / Delegates required!
    ///
    private func startListeningToEvents() {
        // Notifications
        let nc = NSNotificationCenter.defaultCenter()
        nc.addObserver(self, selector: #selector(textViewDidChange), name: UITextViewTextDidChangeNotification, object: self)

        // Delegates
        layoutManager.delegate = self
        attachmentManager.delegate = self
    }

    private func stopListeningToEvents() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
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
        font = defaultFont

        storage.setHTML(html, withDefaultFontDescriptor: font!.fontDescriptor())
        attachmentManager.reloadAttachments()
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
        var identifiers = [String]()

        if storage.length == 0 {
            return identifiers
        }

        if range.length == 0 {
            return formatIdentifiersAtIndex(range.location)
        }

        if boldFormattingSpansRange(range) {
            identifiers.append(FormattingIdentifier.Bold.rawValue)
        }

        if italicFormattingSpansRange(range) {
            identifiers.append(FormattingIdentifier.Italic.rawValue)
        }

        if underlineFormattingSpansRange(range) {
            identifiers.append(FormattingIdentifier.Underline.rawValue)
        }

        if strikethroughFormattingSpansRange(range) {
            identifiers.append(FormattingIdentifier.Strikethrough.rawValue)
        }

        if linkFormattingSpansRange(range) {
            identifiers.append(FormattingIdentifier.Link.rawValue)
        }

        return identifiers
    }


    /// Get a list of format identifiers at a specific index as a String array.
    ///
    /// - Parameters:
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
            identifiers.append(FormattingIdentifier.Bold.rawValue)
        }

        if formattingAtIndexContainsItalic(index) {
            identifiers.append(FormattingIdentifier.Italic.rawValue)
        }

        if formattingAtIndexContainsUnderline(index) {
            identifiers.append(FormattingIdentifier.Underline.rawValue)
        }

        if formattingAtIndexContainsStrikethrough(index) {
            identifiers.append(FormattingIdentifier.Strikethrough.rawValue)
        }

        if formattingAtIndexContainsBlockquote(index) {
            identifiers.append(FormattingIdentifier.Blockquote.rawValue)
        }

        if formattingAtIndexContainsLink(index) {
            identifiers.append(FormattingIdentifier.Link.rawValue)
        }

        return identifiers
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
        print("ordered")
    }


    /// Adds or removes a unordered list style from the specified range.
    ///
    /// - Paramters:
    ///     - range: The NSRange to edit.
    ///
    public func toggleUnorderedList(range range: NSRange) {
        print("unordered")
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


    /// Adds a link to the desiganted url on the specified range.
    ///
    /// - Parameters:
    ///     - url: the NSURL to link to.
    ///     - title: the text for the link
    ///     - range: The NSRange to edit.
    public func setLink(url: NSURL, title: String, inRange range: NSRange) {
        if range.length > 0 {
            storage.setLink(url, forRange: range)
            storage.replaceCharactersInRange(range, withString: title)
        } else {
            let index = range.location
            let length = title.characters.count
            let insertionRange = NSMakeRange(index, length)
            storage.replaceCharactersInRange(range, withString: title)
            storage.setLink(url, forRange: insertionRange)
        }
    }

    public func removeLink(inRange range:NSRange) {
        storage.removeLink(inRange: range)
    }

    // MARK: - Embeds


    /// Inserts an image at the specified index
    ///
    /// - Parameters:
    ///     - path: The path of the image to be inserted.
    ///     - index: The character index at which to insert the image.
    ///
    public func insertImage(image: UIImage, index: Int) {
        let identifier = NSUUID().UUIDString
        let attachment = AztecTextAttachment(identifier: identifier)
        attachment.kind = .Image(image: image)

        // Inject the Attachment and Layout
        let insertionRange = NSMakeRange(index, 0)
        let attachmentString = NSAttributedString(attachment: attachment)
        textStorage.replaceCharactersInRange(insertionRange, withAttributedString: attachmentString)

        // Move the cursor after the attachment
        let selectionRange = NSMakeRange(index + attachmentString.length + 1, 0)
        selectedRange = selectionRange

        // Make sure to reload + layout
        attachmentManager.reloadAttachments()
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
        if let attr = storage.attribute(NSUnderlineStyleAttributeName, atIndex: index, effectiveRange: &effectiveRange),
            let value = attr as? Int {

            return value == NSUnderlineStyle.StyleSingle.rawValue && NSEqualRanges(range, NSIntersectionRange(range, effectiveRange))
        }
        return false
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
        if let attr = storage.attribute(NSStrikethroughStyleAttributeName, atIndex: index, effectiveRange: &effectiveRange),
            let value = attr as? Int {

            return value == NSUnderlineStyle.StyleSingle.rawValue && NSEqualRanges(range, NSIntersectionRange(range, effectiveRange))
        }
        return false
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
        if let attr = storage.attribute(NSLinkAttributeName, atIndex: index, effectiveRange: &effectiveRange) {

           return NSEqualRanges(range, NSIntersectionRange(range, effectiveRange))
        }
        return false
    }

    /**
     Returns an NSURL if the specified range as attached a link attribute

     - parameter range: The NSRange to inspect

     - returns: the NSURL if available
     */
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
        if let attr = storage.attribute(NSLinkAttributeName, atIndex: index, effectiveRange: &effectiveRange) {
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
        if let attr = storage.attribute(NSParagraphStyleAttributeName, atIndex: index, effectiveRange: &effectiveRange),
            let value = attr as? NSParagraphStyle {

            return value.headIndent == Metrics.defaultIndentation && NSEqualRanges(range, NSIntersectionRange(range, effectiveRange))
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
    /// - Parameters:
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

    /// Check if the link attribute exists at the specified index.
    ///
    /// - Parameters:
    ///     - index: The character index to inspect.
    ///
    /// - Returns: True if the attribute exists at the specified index.
    ///
    public func formattingAtIndexContainsLink(index: Int) -> Bool {
        guard let attr = storage.attribute(NSLinkAttributeName, atIndex: index, effectiveRange: nil) else {
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
}


// MARK: - NSLayoutManagerDelegate

extension TextView: NSLayoutManagerDelegate
{

}

// MARK: - AztecAttachmentManagerDelegate

extension TextView: AztecAttachmentManagerDelegate
{
    public func attachmentManager(attachmentManager: AztecAttachmentManager, viewForAttachment attachment: AztecTextAttachment) -> UIView? {
        guard let kind = attachment.kind else {
            return nil
        }

        switch kind {
        case .MissingImage:
            let missingImageView = UIImageView(image: defaultMissingImage)
            return missingImageView
        case .RemoteImage(let url):
            if let mediaDelegate = mediaDelegate {

                let success = { [weak self] (image: UIImage) -> Void in
                    self?.attachmentManager.assignView(UIImageView(image: image), forAttachment: attachment)
                }

                let failure = { [weak self] () -> () in
                    self?.attachmentManager.assignView(UIImageView(image: self?.defaultMissingImage), forAttachment: attachment)
                }

                let placeholderImage = mediaDelegate.image(forTextView: self, atUrl: url, onSuccess: success, onFailure: failure)
                let placeholderImageView = UIImageView(image: placeholderImage)
                return placeholderImageView
            } else {
                return UIImageView(image: defaultMissingImage)
            }

        case .Image(let image):
            return UIImageView(image: image)
        }
    }
}


// MARK: - Notification Handlers

extension TextView
{
    func textViewDidChange(note: NSNotification) {
        attachmentManager.reloadOrLayoutAttachmentsAsNeeded()
    }
}
