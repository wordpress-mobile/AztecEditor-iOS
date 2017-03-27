import Foundation
import UIKit


/// Implemented by a class taking care of handling attachments for the storage.
///
protocol TextStorageAttachmentsDelegate {

    /// Provides images for attachments that are part of the storage
    ///
    /// - Parameters:
    ///     - storage: The storage that is requesting the image.
    ///     - attachment: The attachment that is requesting the image.
    ///     - url: url for the image.
    ///     - success: Callback block to be invoked with the image fetched from the url.
    ///     - failure: Callback block to be invoked when an error occurs when fetching the image.
    ///
    /// - Returns: returns a temporary UIImage to be used while the request is happening
    ///
    func storage(
        _ storage: TextStorage,
        attachment: TextAttachment,
        imageForURL url: URL,
        onSuccess success: @escaping (UIImage) -> (),
        onFailure failure: @escaping () -> ()) -> UIImage
    
    func storage(_ storage: TextStorage, missingImageForAttachment: TextAttachment) -> UIImage
    
    /// Called when an image is about to be added to the storage as an attachment, so that the
    /// delegate can specify an URL where that image is available.
    ///
    /// - Parameters:
    ///     - storage: The storage that is requesting the image.
    ///     - image: The image that was added to the storage.
    ///
    /// - Returns: the requested `NSURL` where the image is stored.
    ///
    func storage(_ storage: TextStorage, urlForAttachment attachment: TextAttachment) -> URL

    /// Called when a attachment is removed from the storage.
    ///
    /// - Parameters:
    ///   - textView: The textView where the attachment was removed.
    ///   - attachmentID: The attachment identifier of the media removed.
    ///
    func storage(_ storage: TextStorage, deletedAttachmentWithID attachmentID: String)

    /// Provides the Bounds required to represent a given attachment, within a specified line fragment.
    ///
    /// - Parameters:
    ///     - storage: The storage that is requesting the bounds.
    ///     - attachment: CommentAttachment about to be rendered.
    ///     - lineFragment: Line Fragment in which the glyph would be rendered.
    ///
    /// - Returns: Rect specifying the Bounds for the comment attachment
    ///
    func storage(_ storage: TextStorage, boundsForComment attachment: CommentAttachment, with lineFragment: CGRect) -> CGRect

    /// Provides the (Optional) Image Representation of the specified size, for a given Attachment.
    ///
    /// - Parameters:
    ///     - storage: The storage that is requesting the bounds.
    ///     - attachment: CommentAttachment about to be rendered.
    ///     - size: Expected Image Size
    ///
    /// - Returns: (Optional) UIImage representation of the Comment Attachment.
    ///
    func storage(_ storage: TextStorage, imageForComment attachment: CommentAttachment, with size: CGSize) -> UIImage?
}


/// Custom NSTextStorage
///
open class TextStorage: NSTextStorage {

    fileprivate var textStore = NSMutableAttributedString(string: "", attributes: nil)
    fileprivate let dom = Libxml2.DOMString()

    // MARK: - Visual only elements

    private let visualOnlyElementFactory = VisualOnlyElementFactory()

    // MARK: - Undo Support
    
    public var undoManager: UndoManager? {
        get {
            return dom.undoManager
        }
        
        set {
            dom.undoManager = newValue
        }
    }
    
    /// Call this method to know if the DOM should be updated, or if the undo manager will take care
    /// of it.
    ///
    /// The undo manager will take care of updating the DOM whenever an undo or redo operation
    /// is triggered.
    ///
    /// - Returns: `true` if the DOM must be updated, or `false` if the undo manager will take care.
    ///
    private func mustUpdateDOM() -> Bool {
        guard let undoManager = undoManager else {
            return true
        }
        
        return !undoManager.isUndoing
    }
    
    // MARK: - NSTextStorage

    override open var string: String {
        return textStore.string
    }

    // MARK: - Attachments

    var attachmentsDelegate: TextStorageAttachmentsDelegate!

    open func TextAttachments() -> [TextAttachment] {
        let range = NSMakeRange(0, length)
        var attachments = [TextAttachment]()
        enumerateAttribute(NSAttachmentAttributeName, in: range, options: []) { (object, range, stop) in
            if let attachment = object as? TextAttachment {
                attachments.append(attachment)
            }
        }

        return attachments
    }

    open func range(forAttachment attachment: TextAttachment) -> NSRange? {

        var range: NSRange?

        textStore.enumerateAttachmentsOfType(TextAttachment.self) { (currentAttachment, currentRange, stop) in
            if attachment == currentAttachment {
                range = currentRange
                stop.pointee = true
            }
        }

        return range
    }
    
    // MARK: - NSAttributedString preprocessing

    private func preprocessAttributesForInsertion(_ attributedString: NSAttributedString) -> NSAttributedString {
        let stringWithAttachments = preprocessAttachmentsForInsertion(attributedString)
        let stringWithParagraphs = preprocessParagraphsForInsertion(stringWithAttachments)

        return stringWithParagraphs
    }

    private func preprocessParagraphsForInsertion(_ attributedString: NSAttributedString) -> NSAttributedString {

        let fullRange = NSRange(location: 0, length: attributedString.length)
        let finalString = NSMutableAttributedString(attributedString: attributedString)

        attributedString.enumerateAttribute(NSParagraphStyleAttributeName, in: fullRange, options: []) { (value, subRange, stop) in

            guard let paragraphStyle = value as? ParagraphStyle else {
                return
            }

            if paragraphStyle.textList != nil {
                var newlineRange = finalString.mutableString.range(of: String(.newline))

                while newlineRange.location != NSNotFound {

                    let originalAttributes = finalString.attributes(at: newlineRange.location, effectiveRange: nil)
                    let visualOnlyNewline = visualOnlyElementFactory.newline(inheritingAttributes: originalAttributes)

                    finalString.replaceCharacters(in: newlineRange, with: visualOnlyNewline)

                    let nextLocation = newlineRange.location + newlineRange.length
                    let nextLength = subRange.length - nextLocation
                    let nextRange = NSRange(location: nextLocation, length: nextLength)

                    newlineRange = finalString.mutableString.range(of: String(.newline), options: [], range: nextRange)
                }
            }
        }

        return finalString
    }

    /// Preprocesses an attributed string's attachments for insertion in the storage.
    ///
    /// - Important: This method takes care of removing any non-image attachments too.  This may
    ///         change in future versions.
    ///
    /// - Parameters:
    ///     - attributedString: the string we need to preprocess.
    ///
    /// - Returns: the preprocessed string.
    ///
    fileprivate func preprocessAttachmentsForInsertion(_ attributedString: NSAttributedString) -> NSAttributedString {
        assert(attachmentsDelegate != nil)

        let fullRange = NSRange(location: 0, length: attributedString.length)
        let finalString = NSMutableAttributedString(attributedString: attributedString)
        
        attributedString.enumerateAttribute(NSAttachmentAttributeName, in: fullRange, options: []) { (object, range, stop) in
            guard let object = object else {
                return
            }

            guard let textAttachment = object as? NSTextAttachment else {
                assertionFailure("We expected a text attachment object.")
                return
            }

            switch textAttachment {
            case _ as LineAttachment:
                break
            case let attachment as CommentAttachment:
                attachment.delegate = self
            case let attachment as TextAttachment:
                attachment.delegate = self
            default:
                guard let image = textAttachment.image else {
                    // We only suppot image attachments for now. All other attachment types are
                    /// stripped for safety.
                    //
                    finalString.removeAttribute(NSAttachmentAttributeName, range: range)
                    return
                }

                let replacementAttachment = TextAttachment()
                replacementAttachment.delegate = self
                replacementAttachment.image = image
                replacementAttachment.url = attachmentsDelegate.storage(self, urlForAttachment: replacementAttachment)

                finalString.addAttribute(NSAttachmentAttributeName, value: replacementAttachment, range: range)
            }
        }

        return finalString
    }

    fileprivate func detectAttachmentRemoved(in range:NSRange) {
        textStore.enumerateAttachmentsOfType(TextAttachment.self, range: range) { (attachment, range, stop) in
            self.attachmentsDelegate.storage(self, deletedAttachmentWithID: attachment.identifier)
        }
    }

    // MARK: - Overriden Methods

    override open func attributes(at location: Int, effectiveRange range: NSRangePointer?) -> [String : Any] {
        return textStore.length == 0 ? [:] : textStore.attributes(at: location, effectiveRange: range)
    }

    override open func replaceCharacters(in range: NSRange, with str: String) {

        beginEditing()

        if mustUpdateDOM() {
            let targetDomRange = map(visualRange: range)
            let preferLeftNode = doesPreferLeftNode(atCaretPosition: range.location)

            dom.replaceCharacters(inRange: targetDomRange, withString: str, preferLeftNode: preferLeftNode)
        }

        detectAttachmentRemoved(in: range)
        textStore.replaceCharacters(in: range, with: str)
        let nsString = str as NSString
        edited(.editedCharacters, range: range, changeInLength:  nsString.length - range.length)
        
        endEditing()
    }
    
    override open func replaceCharacters(in range: NSRange, with attrString: NSAttributedString) {

        let preprocessedString = preprocessAttributesForInsertion(attrString)

        beginEditing()

        if mustUpdateDOM() {
            let targetDomRange = map(visualRange: range)
            let preferLeftNode = doesPreferLeftNode(atCaretPosition: range.location)

            let domString = preprocessedString.filter(attributeNamed: VisualOnlyAttributeName)
            dom.replaceCharacters(inRange: targetDomRange, withString: domString.string, preferLeftNode: preferLeftNode)

            if targetDomRange.length != range.length {
                dom.deleteBlockSeparator(at: targetDomRange.location)
            }

            applyStylesToDom(from: domString, startingAt: range.location)
        }

        detectAttachmentRemoved(in: range)
        textStore.replaceCharacters(in: range, with: preprocessedString)
        edited([.editedAttributes, .editedCharacters], range: range, changeInLength: attrString.length - range.length)

        endEditing()
    }

    override open func setAttributes(_ attrs: [String : Any]?, range: NSRange) {
        beginEditing()

        if mustUpdateDOM(), let attributes = attrs {
            applyStylesToDom(attributes: attributes, in: range)
        }

        textStore.setAttributes(attrs, range: range)
        edited(.editedAttributes, range: range, changeInLength: 0)
        
        endEditing()
    }

    // MARK: - Entry point for calculating style differences

    /// This method applies the styles in the specified attributes dictionary, to the DOM in the
    /// specified range.  To do so, it calculates the differences and applies them.
    ///
    /// - Parameters:
    ///     - attributes: the attributes to apply.
    ///     - range: the range to apply the styles to.
    ///
    private func applyStylesToDom(attributes: [String : Any], in range: NSRange) {
        textStore.enumerateAttributeDifferences(in: range, against: attributes, do: { (subRange, key, sourceValue, targetValue) in

            let domRange = map(visualRange: subRange)

            processAttributesDifference(in: domRange, key: key, sourceValue: sourceValue, targetValue: targetValue)
        })
    }

    /// This method applies the styles from the specified attributed string, to the DOM, starting
    /// at the specified location, and moving ahead for the length of the attributed string.
    ///
    /// This makes sense only if the attributed string has already been added to the DOM, as a way
    /// to apply the styles for that string.
    ///
    /// - Parameters:
    ///     - attributedString: the attributed string containing the styles we want to apply.
    ///     - location: the starting location where the styles should be applied in the DOM.
    ///         It's the offset this method will use to apply the styles found in the source string.
    ///
    private func applyStylesToDom(from attributedString: NSAttributedString, startingAt location: Int) {
        let originalAttributes = location < textStore.length ? textStore.attributes(at: location, effectiveRange: nil) : [:]
        let fullRange = NSRange(location: 0, length: attributedString.length)

        let domLocation = map(visualLocation: location)

        attributedString.enumerateAttributeDifferences(in: fullRange, against: originalAttributes, do: { (subRange, key, sourceValue, targetValue) in
            // The source and target values are inverted since we're enumerating on the new string.

            let domRange = NSRange(location: domLocation + subRange.location, length: subRange.length)

            processAttributesDifference(in: domRange, key: key, sourceValue: targetValue, targetValue: sourceValue)
        })
    }

    /// Check the difference in styles and applies the necessary changes to the DOM string.
    ///
    /// - Parameters:
    ///   - domRange: the range to check
    ///   - key: the attribute style key
    ///   - sourceValue: the original value of the attribute
    ///   - targetValue: the new value of the attribute
    ///
    private func processAttributesDifference(in domRange: NSRange, key: String, sourceValue: Any?, targetValue: Any?) {
        let isLineAttachment = sourceValue is LineAttachment || targetValue is LineAttachment
        let isCommentAttachment = sourceValue is CommentAttachment || targetValue is CommentAttachment

        switch(key) {
        case NSFontAttributeName:
            let sourceFont = sourceValue as? UIFont
            let targetFont = targetValue as? UIFont

            processFontDifferences(in: domRange, betweenOriginal: sourceFont, andNew: targetFont)
        case NSStrikethroughStyleAttributeName:
            let sourceStyle = sourceValue as? NSNumber
            let targetStyle = targetValue as? NSNumber

            processStrikethroughDifferences(in: domRange, betweenOriginal: sourceStyle, andNew: targetStyle)
        case NSUnderlineStyleAttributeName:
            let sourceStyle = sourceValue as? NSNumber
            let targetStyle = targetValue as? NSNumber

            processUnderlineDifferences(in: domRange, betweenOriginal: sourceStyle, andNew: targetStyle)
        case NSAttachmentAttributeName where isLineAttachment:
            let sourceAttachment = sourceValue as? LineAttachment
            let targetAttachment = targetValue as? LineAttachment

            processLineAttachmentDifferences(in: domRange, betweenOriginal: sourceAttachment, andNew: targetAttachment)
        case NSAttachmentAttributeName where isCommentAttachment:
            let sourceAttachment = sourceValue as? CommentAttachment
            let targetAttachment = targetValue as? CommentAttachment

            processCommentAttachmentDifferences(in: domRange, betweenOriginal: sourceAttachment, andNew: targetAttachment)
        case NSAttachmentAttributeName:
            let sourceAttachment = sourceValue as? TextAttachment
            let targetAttachment = targetValue as? TextAttachment

            processAttachmentDifferences(in: domRange, betweenOriginal: sourceAttachment, andNew: targetAttachment)
        case NSParagraphStyleAttributeName:
            let sourceStyle = sourceValue as? ParagraphStyle
            let targetStyle = targetValue as? ParagraphStyle
            processBlockquoteDifferences(in: domRange, betweenOriginal: sourceStyle?.blockquote, andNew: targetStyle?.blockquote)

            processHeaderDifferences(in: domRange, betweenOriginal: sourceStyle?.headerLevel, andNew: targetStyle?.headerLevel)
        case NSLinkAttributeName:
            let sourceStyle = sourceValue as? URL
            let targetStyle = targetValue as? URL
            processLinkDifferences(in: domRange, betweenOriginal: sourceStyle, andNew: targetStyle)
        default:
            break
        }
    }

    // MARK: - Calculating and applying style differences

    /// Processes differences in a font object, and applies them to the DOM in the specified range.
    ///
    /// - Parameters:
    ///     - range: the range in the DOM where the differences must be applied.
    ///     - originalFont: the original font object.
    ///     - newFont: the new font object.
    ///
    private func processFontDifferences(in range: NSRange, betweenOriginal originalFont: UIFont?, andNew newFont: UIFont?) {
        processBoldDifferences(in: range, betweenOriginal: originalFont, andNew: newFont)
        processItalicDifferences(in: range, betweenOriginal: originalFont, andNew: newFont)
    }

    /// Processes differences in the bold trait of two font objects, and applies them to the DOM in
    /// the specified range.
    ///
    /// - Parameters:
    ///     - range: the range in the DOM where the differences must be applied.
    ///     - originalFont: the original font object.
    ///     - newFont: the new font object.
    ///
    private func processBoldDifferences(in range: NSRange, betweenOriginal originalFont: UIFont?, andNew newFont: UIFont?) {
        let oldIsBold = originalFont?.containsTraits(.traitBold) ?? false
        let newIsBold = newFont?.containsTraits(.traitBold) ?? false

        let addBold = !oldIsBold && newIsBold
        let removeBold = oldIsBold && !newIsBold

        if addBold {
            dom.applyBold(spanning: range)
        } else if removeBold {
            dom.removeBold(spanning: range)
        }
    }

    /// Process difference in attachmente properties, and applies them to the DOM in the specified range
    ///
    /// - Parameters:
    ///   - range: the range in the DOM where the differences must be applied.
    ///   - original: the original attachment existing in the range if any.
    ///   - new: the new attachment to apply to the range if any.
    ///
    private func processAttachmentDifferences(in range: NSRange, betweenOriginal original: TextAttachment?, andNew new: TextAttachment?) {

        let originalUrl = original?.url
        let newUrl = new?.url

        let addImageUrl = originalUrl == nil && newUrl != nil
        let removeImageUrl = originalUrl != nil && newUrl == nil

        if addImageUrl {
            guard let urlToAdd = newUrl else {
                assertionFailure("This should not be possible.  Review your logic.")
                return
            }

            dom.replace(range, with: urlToAdd)
        } else if removeImageUrl {
            dom.removeImage(spanning: range)
        }
    }

    private func processLineAttachmentDifferences(in range: NSRange, betweenOriginal original: LineAttachment?, andNew new: LineAttachment?) {

        dom.replaceWithHorizontalRuler(range)
    }

    private func processCommentAttachmentDifferences(in range: NSRange, betweenOriginal original: CommentAttachment?, andNew new: CommentAttachment?) {
        guard let newAttachment = new else {
            return
        }

        dom.replace(range, with: newAttachment.text)
    }


    /// Processes differences in the italic trait of two font objects, and applies them to the DOM
    /// in the specified range.
    ///
    /// - Parameters:
    ///     - range: the range in the DOM where the differences must be applied.
    ///     - originalFont: the original font object.
    ///     - newFont: the new font object.
    ///
    private func processItalicDifferences(in range: NSRange, betweenOriginal originalFont: UIFont?, andNew newFont: UIFont?) {
        let oldIsItalic = originalFont?.containsTraits(.traitItalic) ?? false
        let newIsItalic = newFont?.containsTraits(.traitItalic) ?? false

        let addItalic = !oldIsItalic && newIsItalic
        let removeItalic = oldIsItalic && !newIsItalic

        if addItalic {
            dom.applyItalic(spanning: range)
        } else if removeItalic {
            dom.removeItalic(spanning: range)
        }
    }

    /// Processes differences in two strikethrough styles, and applies them to the DOM in the
    /// specified range.
    ///
    /// - Parameters:
    ///     - range: the range in the DOM where the differences must be applied.
    ///     - originalFont: the original font object.
    ///     - newFont: the new font object.
    ///
    private func processStrikethroughDifferences(in range: NSRange, betweenOriginal originalStyle: NSNumber?, andNew newStyle: NSNumber?) {

        let sourceStyle = originalStyle ?? 0
        let targetStyle = newStyle ?? 0

        // At some point we'll support different styles.  For now we only check if ANY style is
        // set.
        //
        let addStyle = sourceStyle == 0 && targetStyle == 1
        let removeStyle = sourceStyle == 1 && targetStyle == 0

        if addStyle {
            dom.applyStrikethrough(spanning: range)
        } else if removeStyle {
            dom.removeStrikethrough(spanning: range)
        }
    }

    /// Processes differences in two underline styles, and applies them to the DOM in the specified
    /// range.
    ///
    /// - Parameters:
    ///     - range: the range in the DOM where the differences must be applied.
    ///     - originalFont: the original font object.
    ///     - newFont: the new font object.
    ///
    private func processUnderlineDifferences(in range: NSRange, betweenOriginal originalStyle: NSNumber?, andNew newStyle: NSNumber?) {

        let sourceStyle = originalStyle ?? 0
        let targetStyle = newStyle ?? 0

        // At some point we'll support different styles.  For now we only check if ANY style is
        // set.
        //
        let addStyle = sourceStyle == 0 && targetStyle == 1
        let removeStyle = sourceStyle == 1 && targetStyle == 0

        if addStyle {
            dom.applyUnderline(spanning: range)
        } else if removeStyle {
            dom.removeUnderline(spanning: range)
        }
    }

    /// Processes differences in blockquote styles, and applies them to the DOM in the specified
    /// range.
    ///
    /// - Parameters:
    ///     - range: the range in the DOM where the differences must be applied.
    ///     - originalStyle: the original Blockquote object if any.
    ///     - newStyle: the new Blockquote object.
    ///
    private func processBlockquoteDifferences(in range: NSRange, betweenOriginal originalStyle: Blockquote?, andNew newStyle: Blockquote?) {

        let addStyle = originalStyle == nil && newStyle != nil
        let removeStyle = originalStyle != nil && newStyle == nil

        if addStyle {
            dom.applyBlockquote(spanning: range)
        } else if removeStyle {
            dom.removeBlockquote(spanning: range)
        }
    }

    /// Processes differences in header styles, and applies them to the DOM in the specified
    /// range.
    ///
    /// - Parameters:
    ///     - range: the range in the DOM where the differences must be applied.
    ///     - originalHeaderLevel: the original font object.
    ///     - newHeaderLevel: the new font object.
    ///
    private func processHeaderDifferences(in range: NSRange, betweenOriginal originalHeaderLevel: Int?, andNew newHeaderLevel: Int?) {

        let sourceHeader = originalHeaderLevel ?? 0
        let targetHeader = newHeaderLevel ?? 0

        let addStyle = sourceHeader == 0 && targetHeader > 0
        let removeStyle = sourceHeader > 0 && targetHeader == 0

        if addStyle {
            dom.applyHeader(targetHeader, spanning: range)
        } else if removeStyle {
            dom.removeHeader(sourceHeader, spanning: range)
        }
    }

    /// Processes differences in link styles, and applies them to the DOM in the specified
    /// range.
    ///
    /// - Parameters:
    ///     - range: the range in the DOM where the differences must be applied.
    ///     - originalURL: the original link URL object if any.
    ///     - newURL: the new link URL object if any.
    ///
    private func processLinkDifferences(in range: NSRange, betweenOriginal originalURL: URL?, andNew newURL: URL?) {

        let addStyle = originalURL == nil && newURL != nil
        let removeStyle = originalURL != nil && newURL == nil

        if addStyle {            
            dom.applyLink(newURL, spanning: range)
        } else if removeStyle {
            dom.removeLink(spanning: range)
        }
    }


    // MARK: - Range Mapping: Visual vs HTML

    private func canAppendToNodeRepresentedByCharacter(atIndex index: Int) -> Bool {
        return !hasNewLine(atIndex: index)
            && !hasHorizontalLine(atIndex: index)
            && !hasCommentMarker(atIndex: index)
            && !hasVisualOnlyElement(atIndex: index)
    }

    private func doesPreferLeftNode(atCaretPosition caretPosition: Int) -> Bool {
        guard caretPosition != 0,
            let previousLocation = textStore.string.location(before:caretPosition) else {
            return false
        }

        return canAppendToNodeRepresentedByCharacter(atIndex: previousLocation)
    }

    private func hasHorizontalLine(atIndex index: Int) -> Bool {
        guard let attachment = attribute(NSAttachmentAttributeName, at: index, effectiveRange: nil),
            attachment is LineAttachment else {
                return false
        }

        return true
    }

    private func hasCommentMarker(atIndex index: Int) -> Bool {
        guard let attachment = attribute(NSAttachmentAttributeName, at: index, effectiveRange: nil),
            attachment is CommentAttachment else {
            return false
        }

        return true
    }

    private func hasNewLine(atIndex index: Int) -> Bool {
        if index >= textStore.length || index < 0 {
            return false
        }
        let nsString = string as NSString
        return nsString.substring(from: index).hasPrefix(String(Character(.newline)))        
    }

    private func hasVisualOnlyElement(atIndex index: Int) -> Bool {
        return attribute(VisualOnlyAttributeName, at: index, effectiveRange: nil) != nil
    }

    private func map(visualLocation: Int) -> Int {

        let locationRange = NSRange(location: visualLocation, length: 0)
        let mappedRange = textStore.map(range: locationRange, bySubtractingAttributeNamed: VisualOnlyAttributeName)

        return mappedRange.location
    }

    private func map(visualRange: NSRange) -> NSRange {
        return textStore.map(range: visualRange, bySubtractingAttributeNamed: VisualOnlyAttributeName)
    }
    
    // MARK: - Styles: Toggling
    @discardableResult func toggle(formatter: AttributeFormatter, at range: NSRange) -> NSRange {
        let applicationRange = formatter.applicationRange(for: range, in: self)
        if applicationRange.length == 0, !formatter.worksInEmptyRange() {
            return applicationRange
        }

        return formatter.toggle(in: self, at: applicationRange)
    }

    /// Insert Image Element at the specified range using url as source
    ///
    /// - parameter url: the source URL of the image
    /// - parameter position: the position to insert the image
    /// - parameter placeHolderImage: an image to display while the image from sourceURL is being prepared
    ///
    /// - returns: the attachment object that was created and inserted on the text
    ///
    func insertImage(sourceURL url: URL, atPosition position:Int, placeHolderImage: UIImage, identifier: String = UUID().uuidString) -> TextAttachment {
        let attachment = TextAttachment(identifier: identifier)
        attachment.delegate = self
        attachment.url = url
        attachment.image = placeHolderImage

        // Inject the Attachment and Layout
        let insertionRange = NSMakeRange(position, 0)
        let attachmentString = NSAttributedString(attachment: attachment)
        replaceCharacters(in: insertionRange, with: attachmentString)

        return attachment
    }

    /// Insert an HR element at the specifice range
    ///
    /// - Parameter range: the range where the element will be inserted
    ///
    func replaceRangeWithHorizontalRuler(_ range: NSRange) {
        let line = LineAttachment()

        let attachmentString = NSAttributedString(attachment: line)
        replaceCharacters(in: range, with: attachmentString)        
    }

    // MARK: - Attachments


    /// Return the attachment, if any, corresponding to the id provided
    ///
    /// - Parameter id: the unique id of the attachment
    /// - Returns: the attachment object
    ///
    open func attachment(withId id: String) -> TextAttachment? {
        var foundAttachment: TextAttachment? = nil
        enumerateAttachmentsOfType(TextAttachment.self) { (attachment, range, stop) in
            if attachment.identifier == id {
                foundAttachment = attachment
                stop.pointee = true
            }
        }
        return foundAttachment
    }


    /// Updates the attachment attributes to the values provided.
    ///
    /// - Parameters:
    ///   - attachment: the attachment to update
    ///   - alignment: the alignment value
    ///   - size: the size to use
    ///   - url: the image URL for the image
    ///
    open func update(attachment: TextAttachment,
                                  alignment: TextAttachment.Alignment,
                                  size: TextAttachment.Size,
                                  url: URL) {
        attachment.alignment = alignment
        attachment.size = size
        attachment.url = url
        let rangesForAttachment = ranges(forAttachment:attachment)

        let domRanges = rangesForAttachment.map { range -> NSRange in
            map(visualRange: range)
        }
        
        dom.updateImage(spanning: domRanges, url: url, size: size, alignment: alignment)
    }

    /// Removes the attachments that match the attachament identifier provided from the storage
    ///
    /// - Parameter attachmentID: the unique id of the attachment
    ///
    open func remove(attachmentID: String) {
        enumerateAttachmentsOfType(TextAttachment.self) { (attachment, range, stop) in
            if attachment.identifier == attachmentID {
                self.replaceCharacters(in: range, with: NSAttributedString(string: ""))
                stop.pointee = true
            }
        }
    }

    /// Removes all of the TextAttachments from the storage
    ///
    open func removeTextAttachments() {
        var ranges = [NSRange]()
        enumerateAttachmentsOfType(TextAttachment.self) { (attachment, range, _) in
            ranges.append(range)
        }

        var delta = 0
        for range in ranges {
            let corrected = NSRange(location: range.location - delta, length: range.length)
            replaceCharacters(in: corrected, with: NSAttributedString(string: ""))
            delta += range.length
        }
    }

    /// Inserts the Comment Attachment at the specified position
    ///
    @discardableResult
    open func replaceRangeWithCommentAttachment(_ range: NSRange, text: String, attributes: [String: Any]) -> CommentAttachment {
        let attachment = CommentAttachment()
        attachment.text = text

        let stringWithAttachment = NSAttributedString(attachment: attachment, attributes: attributes)
        replaceCharacters(in: range, with: stringWithAttachment)

        return attachment
    }


    // MARK: - Toggle Attributes

    fileprivate func toggleAttribute(_ attributeName: String, value: AnyObject, range: NSRange) {

        var effectiveRange = NSRange()
        let enable: Bool
        
        if attribute(attributeName, at: range.location, longestEffectiveRange: &effectiveRange, in: range) != nil {
            let intersection = range.intersect(withRange: effectiveRange)
            
            if let intersection = intersection {
                enable = !NSEqualRanges(range, intersection)
            } else {
                enable = true
            }
        } else {
            enable = true
        }
        
        if enable {
            addAttribute(attributeName, value: value, range: range)
        } else {
            
            /// We should be calculating what attributes to remove in `TextStorage.setAttributes()`
            /// but since that may take a while to implement, we need this workaround until it's ready.
            ///
            switch attributeName {
            case NSStrikethroughStyleAttributeName:
                dom.removeStrikethrough(spanning: range)
            case NSUnderlineStyleAttributeName:
                dom.removeUnderline(spanning: range)
            default:
                break
            }
            
            removeAttribute(attributeName, range: range)
        }
    }

    // MARK: - HTML Interaction

    open func getHTML() -> String {
        return dom.getHTML()
    }

    func setHTML(_ html: String, withDefaultFontDescriptor defaultFontDescriptor: UIFontDescriptor) {
        
        let attributedString = dom.setHTML(html, withDefaultFontDescriptor: defaultFontDescriptor)
        
        let originalLength = textStore.length
        textStore = NSMutableAttributedString(attributedString: attributedString)
        textStore.enumerateAttachmentsOfType(TextAttachment.self) { [weak self] (attachment, _, _) in
            attachment.delegate = self
        }
        textStore.enumerateAttachmentsOfType(CommentAttachment.self) { [weak self] (attachment, _, _) in
            attachment.delegate = self
        }

        edited([.editedAttributes, .editedCharacters], range: NSRange(location: 0, length: originalLength), changeInLength: textStore.length - originalLength)
    }
}


// MARK: - TextStorage: TextAttachmentDelegate Methods
//
extension TextStorage: TextAttachmentDelegate {

    func textAttachment(
        _ textAttachment: TextAttachment,
        imageForURL url: URL,
        onSuccess success: @escaping (UIImage) -> (),
        onFailure failure: @escaping () -> ()) -> UIImage
    {
        assert(attachmentsDelegate != nil)
        return attachmentsDelegate.storage(self, attachment: textAttachment, imageForURL: url, onSuccess: success, onFailure: failure)
    }

}


// MARK: - TextStorage: CommentAttachmentDelegate Methods
//
extension TextStorage: CommentAttachmentDelegate {

    func commentAttachment(_ commentAttachment: CommentAttachment, imageForSize size: CGSize) -> UIImage? {
        assert(attachmentsDelegate != nil)
        return attachmentsDelegate.storage(self, imageForComment: commentAttachment, with: size)
    }

    func commentAttachment(_ commentAttachment: CommentAttachment, boundsForLineFragment fragment: CGRect) -> CGRect {
        assert(attachmentsDelegate != nil)
        return attachmentsDelegate.storage(self, boundsForComment: commentAttachment, with: fragment)
    }
}
