
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
    func textView(textView: TextView, imageAtUrl imageURL: NSURL, onSuccess success: UIImage -> Void, onFailure failure: Void -> Void) -> UIImage
    
    func textView(textView: TextView, urlForImage image: UIImage) -> NSURL
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
        previousSelectedRange = NSRange.zero
        super.init(frame: CGRect(x: 0, y: 0, width: 10, height: 10), textContainer: container)
        
        allowsEditingTextAttributes = true
        storage.attachmentsDelegate = self
        previousSelectedRange = selectedRange
    }
    
    required public init?(coder aDecoder: NSCoder) {

        defaultFont = UIFont.systemFontOfSize(14)
        defaultMissingImage = Gridicon.iconOfType(.Image)
        previousSelectedRange = NSRange.zero
        super.init(coder: aDecoder)
        
        allowsEditingTextAttributes = true
        previousSelectedRange = selectedRange
    }

    //MARK: - Selection Logic

    public override var selectedTextRange: UITextRange? {
        didSet {
            selectionChanged()
        }
    }

    // MARK: - Intersect copy paste operations

    public override func cut(sender: AnyObject?) {
        let originalRange = selectedRange
        super.cut(sender)
        refreshListsOnlyIfListExists(atRange: originalRange)
    }

    public override func paste(sender: AnyObject?) {
        let originalRange = selectedRange
        super.paste(sender)
        refreshListsOnlyIfListExists(atRange: originalRange)
    }

    // MARK: - Intersect keyboard operations

    public override func insertText(text: String) {
        let originalRange = selectedRange
        super.insertText(text)
        refreshListIfNewLinesOn(text: text, range: originalRange)
    }

    public override func deleteBackward() {
        var originalDeletionRange = selectedRange
        originalDeletionRange.location = max(originalDeletionRange.location-1, 0)
        originalDeletionRange.length = 1
        var expandedRange = rangeIgnoringListMarkers(forProposedRange: originalDeletionRange, movingForward: false, growing: true)

        super.deleteBackward()

        if storage.length < 1 {
            return
        }

        if !NSEqualRanges(expandedRange, originalDeletionRange) {
            if expandedRange.location > 1 {
                expandedRange.location = max(expandedRange.location-1, 0)
            } else {
                expandedRange.length -= 1
            }
            storage.replaceCharactersInRange(expandedRange, withAttributedString: NSMutableAttributedString())
            var newSelectionRange = selectedRange
            newSelectionRange.location = selectedRange.location - expandedRange.length
            selectedRange = newSelectionRange
            refreshList(aroundRange:selectedRange)
        }
    }

    private var previousSelectedRange: NSRange

    private func selectionChanged() {
        var movingForward = true
        var growing = true
        if selectedRange.location < previousSelectedRange.location {
            movingForward = false
        }
        if selectedRange.length < previousSelectedRange.length {
            growing = false
        }

        let newRange = rangeIgnoringListMarkers(forProposedRange: selectedRange, movingForward: movingForward, growing: growing)

        previousSelectedRange = newRange
        selectedRange = newRange
    }

    private func rangeIgnoringListMarkers(forProposedRange range: NSRange, movingForward:Bool, growing:Bool) -> NSRange {
        if range.location >= storage.length {
            return range
        }
        var newRange = range
        if newRange.length == 0 {
            var fullRange: NSRange = NSRange.zero
            if storage.attribute(TextListItemMarker.attributeName, atIndex:newRange.location, longestEffectiveRange: &fullRange, inRange: storage.rangeOfEntireString) != nil {
                if movingForward {
                    newRange.location = fullRange.endLocation
                } else {
                    newRange.location = max(fullRange.location-1, 0)
                }
            }
        } else {
            storage.enumerateAttribute(TextListItemMarker.attributeName,
                                       inRange: newRange,
                                       options: []) { (attribute, attributeRange, stop) in
                                        if attribute == nil {
                                            return
                                        }
                                        var fullRange: NSRange = NSRange.zero
                                        if storage.attribute(TextListItemMarker.attributeName, atIndex:attributeRange.location, effectiveRange: &fullRange) == nil {
                                            return
                                        }
                                        if growing {
                                            newRange = NSUnionRange(newRange, fullRange)
                                        } else {
                                            if fullRange.location < newRange.location {
                                                newRange.location = fullRange.endLocation
                                                newRange.length -= fullRange.length-1
                                            } else {
                                                if ( !NSEqualRanges(NSIntersectionRange(fullRange, newRange), fullRange)){
                                                    newRange.length -= fullRange.length
                                                }
                                            }
                                        }
            }
        }
        return newRange
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
    /// - Parameter range: The specified NSRange.
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
    /// - Parameter html: The raw HTML we'd be editing.
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
    }


    // MARK: - Getting format identifiers


    /// Get a list of format identifiers spanning the specified range as a String array.
    ///
    /// - Parameter range: An NSRange to inspect.
    ///
    /// - Returns: A list of identifiers.
    ///
    public func formatIdentifiersSpanningRange(range: NSRange) -> [String] {
        guard storage.length != 0 else {
            // FIXME: if empty string, check typingAttributes
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
    /// - Parameter range: The character index to inspect.
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
    /// - Parameter range: The NSRange to edit.
    ///
    public func toggleBold(range range: NSRange) {
        guard range.length > 0 else {
            return
        }

        storage.toggleBold(range)
    }


    /// Adds or removes a italic style from the specified range.
    ///
    /// - Parameter range: The NSRange to edit.
    ///
    public func toggleItalic(range range: NSRange) {
        guard range.length > 0 else {
            return
        }

        storage.toggleItalic(range)
    }


    /// Adds or removes a underline style from the specified range.
    ///
    /// - Parameter range: The NSRange to edit.
    ///
    public func toggleUnderline(range range: NSRange) {
        guard range.length > 0 else {
            return
        }

        storage.toggleUnderlineForRange(range)
    }


    /// Adds or removes a strikethrough style from the specified range.
    ///
    /// - Parameter range: The NSRange to edit.
    ///
    public func toggleStrikethrough(range range: NSRange) {
        guard range.length > 0 else {
            return
        }

        storage.toggleStrikethrough(range)
    }


    private enum SelectionMarker: String {
        case start = "SelectionStart"
        case end = "SelectionEnd"
    }

    private func markCurrentSelection() {
        let range = selectedRange
        // selection marking
        if range.location + 1 < storage.length {
            storage.addAttribute(SelectionMarker.start.rawValue, value: SelectionMarker.start.rawValue, range: NSRange(location:range.location, length: 1))
        }
        if range.endLocation + 1 < storage.length {
            storage.addAttribute(SelectionMarker.end.rawValue, value: SelectionMarker.end.rawValue, range: NSRange(location:range.location + range.length, length: 1))
        }
    }

    private func restoreMarkedSelection() {
        var selectionStartRange: NSRange = NSRange(location: max(storage.length, 0), length: 0)
        var selectionEndRange: NSRange = selectionStartRange
        storage.enumerateAttribute(SelectionMarker.start.rawValue,
                                   inRange: NSRange(location: 0, length: storage.length),
                                   options: []) { (attribute, range, stop) in
                                    if attribute != nil {
                                        selectionStartRange = range
                                    }
        }

        storage.enumerateAttribute(SelectionMarker.end.rawValue,
                                   inRange: NSRange(location: 0, length: storage.length),
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

    // MARK: - List Code


    /// Refresh Lists attributes when insert new text in the specified range
    ///
    /// - Parameters:
    ///   - text: the text being added
    ///   - range: the range of the insertion of the new text
    private func refreshListIfNewLinesOn(text text:String, range:NSRange) {
        guard text == "\n"
            && range.location + 1 < storage.length
            else {
            refreshListsOnlyIfListExists(atRange: range)
            return
        }
        var afterRange = range
        afterRange.length = 1
        afterRange.location += 1
        let afterString = storage.attributedSubstringFromRange(afterRange).string

        var isBegginingOfListItem = false
        var precedingListItemRange = NSRange.zero
        if storage.length > 0 {

            let positionToCheck = max(min(range.location - 1,storage.length - 1),0)
            isBegginingOfListItem = storage.attribute(TextListItemMarker.attributeName,
                                                      atIndex:positionToCheck,
                                                      effectiveRange: &precedingListItemRange) != nil
        }

        if !(isBegginingOfListItem && afterString == "\n") {
            refreshListsOnlyIfListExists(atRange: range)
        } else {
            var lineMovedRange = afterRange
            lineMovedRange.location += 1
            removeList(aroundRange: lineMovedRange)
            removeList(aroundRange: precedingListItemRange)
            deleteBackward()
        }
    }

    /// Refresh the list attributes in the specified range but only if a list is already present on the line
    ///
    /// - Parameter range: the range to where to update the list attributes
    ///
    private func refreshListsOnlyIfListExists(atRange range:NSRange) {

        if storage.attribute(TextListItem.attributeName,
                             atIndex:max(range.location-1,0),
                             effectiveRange: nil) != nil {
            refreshList(aroundRange: range)
        }
    }

    private func refreshList(aroundRange range: NSRange) {
        let formatter = TextListFormatter()

        markCurrentSelection()

        formatter.updatesList(inString: storage, atRange: range)

        restoreMarkedSelection()
    }

    private func removeList(aroundRange range: NSRange) {
        let formatter = TextListFormatter()

        markCurrentSelection()

        formatter.removeList(inString: storage, atRange: range)

        restoreMarkedSelection()
    }

    /// Adds or removes a ordered list style from the specified range.
    ///
    /// - Parameter range: The NSRange to edit.
    ///
    public func toggleOrderedList(range range: NSRange) {
        let appliedRange = rangeForTextList(range)
        let formatter = TextListFormatter()

        markCurrentSelection()

        formatter.toggleList(ofStyle: .Ordered, inString: storage, atRange: appliedRange)

        restoreMarkedSelection()
    }


    /// Adds or removes a unordered list style from the specified range.
    ///
    /// - Parameter range: The NSRange to edit.
    ///
    public func toggleUnorderedList(range range: NSRange) {
        let appliedRange = rangeForTextList(range)
        let formatter = TextListFormatter()

        markCurrentSelection()

        formatter.toggleList(ofStyle: .Unordered, inString: storage, atRange: appliedRange)

        restoreMarkedSelection()
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
        let formatter = BlockquoteFormatter()
        formatter.toggleAttribute(inTextView: self, atRange: range)
    }


    /// Adds a link to the designated url on the specified range.
    ///
    /// - Parameters:
    ///     - url: the NSURL to link to.
    ///     - title: the text for the link.
    ///     - range: The NSRange to edit.
    ///
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
    /// - Returns: an id of the attachment that can be used for further calls
    public func insertImage(sourceURL url: NSURL, atPosition position: Int, placeHolderImage: UIImage?) -> String {
        let imageId = storage.insertImage(sourceURL: url, atPosition: position, placeHolderImage: placeHolderImage ?? defaultMissingImage)
        let length = NSAttributedString(attachment:NSTextAttachment()).length
        selectedRange = NSMakeRange(position+length, 0)
        return imageId
    }

    public func attachment(withId id: String) -> TextAttachment? {
        return storage.attachment(withId: id);
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
    /// - Parameter point: The point on screen to check for attachments.
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
    /// - Parameter range: The NSRange to inspect.
    ///
    /// - Returns: True if the attribute spans the entire range.
    ///
    public func boldFormattingSpansRange(range: NSRange) -> Bool {
        return storage.fontTrait(.TraitBold, spansRange: range)
    }


    /// Check if the italic attribute spans the specified range.
    ///
    /// - Parameter range: The NSRange to inspect.
    ///
    /// - Returns: True if the attribute spans the entire range.
    ///
    public func italicFormattingSpansRange(range: NSRange) -> Bool {
        return storage.fontTrait(.TraitItalic, spansRange: range)
    }


    /// Check if the underline attribute spans the specified range.
    ///
    /// - Parameter range: The NSRange to inspect.
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
    /// - Parameter range: The NSRange to inspect.
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
    /// - Parameter range: The NSRange to inspect.
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
    /// - Parameter range: The NSRange to inspect.
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
    /// - Parameter range: The NSRange to inspect.
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
    /// - Parameter index: The candidate index. If the index is greater than the max allowed, the max is returned.
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
    /// - Parameter index: The candidate index.
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
    /// - Parameter range: The NSRange in which a TextList should be applied
    ///
    /// Returns: A corrected NSRange, if the original one had empty length.
    ///
    func rangeForTextList(range: NSRange) -> NSRange {
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
    public func formattingAtIndexContainsBold(index: Int) -> Bool {
        return storage.fontTrait(.TraitBold, existsAtIndex: index)
    }


    /// Check if the italic attribute exists at the specified index.
    ///
    /// - Parameter index: The character index to inspect.
    ///
    /// - Returns: True if the attribute exists at the specified index.
    ///
    public func formattingAtIndexContainsItalic(index: Int) -> Bool {
        return storage.fontTrait(.TraitItalic, existsAtIndex: index)
    }


    /// Check if the underline attribute exists at the specified index.
    ///
    /// - Parameter index: The character index to inspect.
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
    /// - Parameter index: The character index to inspect.
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
    /// - Parameter index: The character index to inspect.
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
    /// - Parameter index: The character index to inspect.
    ///
    /// - Returns: True if the attribute exists at the specified index.
    ///
    public func formattingAtIndexContainsBlockquote(index: Int) -> Bool {
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

    /// Updates the attachment properties to the new values
    ///
    /// - parameter attachment: the attachment to update
    /// - parameter alignment:  the alignment value
    /// - parameter size:       the size value
    /// - parameter url:        the attachment url
    ///
    public func update(attachment attachment: TextAttachment,
                                  alignment: TextAttachment.Alignment,
                                  size: TextAttachment.Size,
                                  url: NSURL) {
        storage.update(attachment: attachment, alignment: alignment, size: size, url: url)
        layoutManager.invalidateLayoutForAttachment(attachment)
    }

    /// Update the progress indicator of an attachment
    ///
    /// - Parameters:
    ///   - attachment: the attachment to update
    ///   - progress: the value of progress
    ///
    public func update(attachment attachment: TextAttachment, progress: Double?, progressColor: UIColor = UIColor.blueColor()) {
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
    public func update(attachment attachment: TextAttachment, message: NSAttributedString?) {
        attachment.message = message
        layoutManager.invalidateLayoutForAttachment(attachment)
    }
}

// MARK: - TextStorageImageProvider

extension TextView: TextStorageAttachmentsDelegate {

    func storage(storage: TextStorage, attachment: TextAttachment, imageForURL url: NSURL, onSuccess success: (UIImage) -> (), onFailure failure: () -> ()) -> UIImage {
        
        guard let mediaDelegate = mediaDelegate else {
            fatalError("This class requires a media delegate to be set.")
        }
        
        let placeholderImage = mediaDelegate.textView(self, imageAtUrl: url, onSuccess: success, onFailure: failure)
        return placeholderImage
    }

    func storage(storage: TextStorage, missingImageForAttachment: TextAttachment) -> UIImage {
        return defaultMissingImage
    }
    
    func storage(storage: TextStorage, urlForImage image: UIImage) -> NSURL {
        
        guard let mediaDelegate = mediaDelegate else {
            fatalError("This class requires a media delegate to be set.")
        }
        
        return mediaDelegate.textView(self, urlForImage: image)
    }
}
