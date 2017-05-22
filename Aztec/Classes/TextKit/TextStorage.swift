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
        attachment: NSTextAttachment,
        imageFor url: URL,
        onSuccess success: @escaping (UIImage) -> (),
        onFailure failure: @escaping () -> ()) -> UIImage
    
    func storage(_ storage: TextStorage, missingImageFor attachment: NSTextAttachment) -> UIImage
    
    /// Called when an image is about to be added to the storage as an attachment, so that the
    /// delegate can specify an URL where that image is available.
    ///
    /// - Parameters:
    ///     - storage: The storage that is requesting the image.
    ///     - imageAttachment: The image that was added to the storage.
    ///
    /// - Returns: the requested `NSURL` where the image is stored.
    ///
    func storage(_ storage: TextStorage, urlFor imageAttachment: ImageAttachment) -> URL

    /// Called when a attachment is removed from the storage.
    ///
    /// - Parameters:
    ///   - textView: The textView where the attachment was removed.
    ///   - attachmentID: The attachment identifier of the media removed.
    ///
    func storage(_ storage: TextStorage, deletedAttachmentWith attachmentID: String)

    /// Provides the Bounds required to represent a given attachment, within a specified line fragment.
    ///
    /// - Parameters:
    ///     - storage: The storage that is requesting the bounds.
    ///     - attachment: NSTextAttachment about to be rendered.
    ///     - lineFragment: Line Fragment in which the glyph would be rendered.
    ///
    /// - Returns: Rect specifying the Bounds for the attachment
    ///
    func storage(_ storage: TextStorage, boundsFor attachment: NSTextAttachment, with lineFragment: CGRect) -> CGRect

    /// Provides the (Optional) Image Representation of the specified size, for a given Attachment.
    ///
    /// - Parameters:
    ///     - storage: The storage that is requesting the bounds.
    ///     - attachment: NSTextAttachment about to be rendered.
    ///     - size: Expected Image Size
    ///
    /// - Returns: (Optional) UIImage representation of the attachment.
    ///
    func storage(_ storage: TextStorage, imageFor attachment: NSTextAttachment, with size: CGSize) -> UIImage?
}


/// Custom NSTextStorage
///
open class TextStorage: NSTextStorage {

    fileprivate var textStore = NSMutableAttributedString(string: "", attributes: nil)
    fileprivate let dom = Libxml2.DOMString()

    // MARK: - Workarounds support

    /// To know more about why we need this flag, check the documentation of our `endEditing()`
    /// override.
    ///
    private var allowFixingDOMAttributes = true

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

    open func MediaAttachments() -> [MediaAttachment] {
        let range = NSMakeRange(0, length)
        var attachments = [MediaAttachment]()
        enumerateAttribute(NSAttachmentAttributeName, in: range, options: []) { (object, range, stop) in
            if let attachment = object as? MediaAttachment {
                attachments.append(attachment)
            }
        }

        return attachments
    }

    func range<T : NSTextAttachment>(for attachment: T) -> NSRange? {
        var range: NSRange?

        textStore.enumerateAttachmentsOfType(T.self) { (currentAttachment, currentRange, stop) in
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

            guard value is ParagraphStyle else {
                return
            }

            var newlineRange = finalString.mutableString.range(of: String(.newline))

            while newlineRange.location != NSNotFound {

                let originalAttributes = finalString.attributes(at: newlineRange.location, effectiveRange: nil)

                finalString.replaceCharacters(in: newlineRange, with: NSAttributedString(.paragraphSeparator, attributes: originalAttributes))

                let nextLocation = newlineRange.location + newlineRange.length
                let nextLength = subRange.length - nextLocation
                let nextRange = NSRange(location: nextLocation, length: nextLength)

                newlineRange = finalString.mutableString.range(of: String(.newline), options: [], range: nextRange)
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
            case let attachment as HTMLAttachment:
                attachment.delegate = self
            case let attachment as ImageAttachment:
                attachment.delegate = self
            case let attachment as VideoAttachment:
                attachment.delegate = self
            default:
                guard let image = textAttachment.image else {
                    // We only suppot image attachments for now. All other attachment types are
                    /// stripped for safety.
                    //
                    finalString.removeAttribute(NSAttachmentAttributeName, range: range)
                    return
                }

                let replacementAttachment = ImageAttachment(identifier: NSUUID.init().uuidString)
                replacementAttachment.delegate = self
                replacementAttachment.image = image
                replacementAttachment.url = attachmentsDelegate.storage(self, urlFor: replacementAttachment)

                finalString.addAttribute(NSAttachmentAttributeName, value: replacementAttachment, range: range)
            }
        }

        return finalString
    }

    fileprivate func detectAttachmentRemoved(in range:NSRange) {
        textStore.enumerateAttachmentsOfType(MediaAttachment.self, range: range) { (attachment, range, stop) in
            self.attachmentsDelegate.storage(self, deletedAttachmentWith: attachment.identifier)
        }
    }

    // MARK: - Overriden Methods

    /// Retrieves the attributes for the requested character location.
    ///
    /// - Important: please note that this method returns the style at the character location, and
    ///     NOT at the caret location.  For N characters we always have N+1 character locations.
    ///
    override open func attributes(at location: Int, effectiveRange range: NSRangePointer?) -> [String : Any] {

        guard textStore.length > 0 else {
            return [:]
        }

        return textStore.attributes(at: location, effectiveRange: range)
    }
 
    override open func replaceCharacters(in range: NSRange, with str: String) {

        beginEditing()

        if mustUpdateDOM() {
            replaceCharactersInDOM(in: range, with: str)
        }

        detectAttachmentRemoved(in: range)
        textStore.replaceCharacters(in: range, with: str)

        edited(.editedCharacters, range: range, changeInLength: str.characters.count - range.length)
        
        endEditing()
    }

    override open func replaceCharacters(in range: NSRange, with attrString: NSAttributedString) {

        let preprocessedString = preprocessAttributesForInsertion(attrString)

        beginEditing()

        if mustUpdateDOM() {
            replaceCharactersInDOM(in: range, with: preprocessedString)
        }

        detectAttachmentRemoved(in: range)
        textStore.replaceCharacters(in: range, with: preprocessedString)
        edited([.editedAttributes, .editedCharacters], range: range, changeInLength: attrString.length - range.length)

        endEditing()
    }

    override open func setAttributes(_ attrs: [String : Any]?, range: NSRange) {
        beginEditing()

        if mustUpdateDOM() && allowFixingDOMAttributes && range.length > 0, let attributes = attrs {
            applyStylesToDom(attributes: attributes, in: range)
        }

        textStore.setAttributes(attrs, range: range)
        edited(.editedAttributes, range: range, changeInLength: 0)
        
        endEditing()

        print("Style: \(dom.getHTML())")
    }

    /// This override exists to prevent text replacement from propagating style-changes to the DOM
    /// This should not be a problem in our logic because the DOM is smart enough to update its
    /// style after text modifications.
    ///
    /// This was causing issues specifically with lists.  To understand why, just comment this
    /// method and run the unit tests.
    ///
    override open func endEditing() {
        allowFixingDOMAttributes = false
        super.endEditing()
        allowFixingDOMAttributes = true
    }

    // MARK: - DOM: Replacing Characters

    private func replaceCharactersInDOM(in range: NSRange, with str: String) {

        guard let swiftRange = string.nsRange(fromUTF16NSRange: range) else {
            fatalError()
        }

        if swiftRange.length > 0 || str.characters.count > 0 {
            dom.replaceCharacters(inRange: swiftRange, with: str)
        }
    }

    private func replaceCharactersInDOM(in range: NSRange, with attrString: NSAttributedString) {
        if range.length > 0 || attrString.length > 0 {
            dom.replaceCharacters(inRange: range, with: attrString)
        }
    }

    // MARK: - DOM: Applying Styles

    /// This method applies the styles in the specified attributes dictionary, to the DOM in the
    /// specified range.  To do so, it calculates the differences and applies them.
    ///
    /// - Parameters:
    ///     - attributes: the attributes to apply.
    ///     - range: the range to apply the styles to.
    ///
    private func applyStylesToDom(attributes: [String : Any], in range: NSRange) {

        let canMergeLeft = range.location > 0 ? !textStore.string.isStartOfNewLine(atUTF16Offset: range.location) : false
        let canMergeRight = range.location + range.length < textStore.length - 1 ? !textStore.string.isEndOfLine(atUTF16Offset: range.location + range.length) : false

        textStore.enumerateAttributeDifferences(in: range, against: attributes, do: { (subRange, key, sourceValue, targetValue) in

            guard subRange.length > 0 else {
                return
            }

            guard let swiftSubRange = textStore.string.nsRange(fromUTF16NSRange: subRange) else {
                assertionFailure("The sub-range is not a valid UTF16 range in TextStore.  Review the logic.")
                return
            }

            processAttributesDifference(in: swiftSubRange, key: key, sourceValue: sourceValue, targetValue: targetValue, canMergeLeft: canMergeLeft, canMergeRight: canMergeRight)
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
        let originalAttributes = [String:Any]()
        let fullRange = NSRange(location: 0, length: attributedString.length)

        let canMergeLeft = location > 0 ? !textStore.string.isStartOfNewLine(atUTF16Offset: location) : false
        let canMergeRight = location < textStore.length - 1 ? !textStore.string.isEndOfLine(atUTF16Offset: location) : false

        attributedString.enumerateAttributeDifferences(in: fullRange, against: originalAttributes, do: { (subRange, key, sourceValue, targetValue) in
            // The source and target values are inverted since we're enumerating on the new string.

            let domRange = NSRange(location: location + subRange.location, length: subRange.length)

            guard let swiftDomRange = dom.string().nsRange(fromUTF16NSRange: domRange) else {
                // This should not be possible, but if this ever happens in production it's better to lose
                // the style than it is to crash the editor.
                //
                assertionFailure("Unexpected range conversion problem.")
                return
            }

            processAttributesDifference(in: swiftDomRange, key: key, sourceValue: targetValue, targetValue: sourceValue, canMergeLeft: canMergeLeft, canMergeRight: canMergeRight)
        })
    }

    // MARK: - DOM: Calculating and Applying Style Differences

    /// Check the difference in styles and applies the necessary changes to the DOM string.
    ///
    /// - Parameters:
    ///   - domRange: the range to check
    ///   - key: the attribute style key
    ///   - sourceValue: the original value of the attribute
    ///   - targetValue: the new value of the attribute
    ///
    private func processAttributesDifference(
        in domRange: NSRange,
        key: String,
        sourceValue: Any?,
        targetValue: Any?,
        canMergeLeft: Bool = true,
        canMergeRight: Bool = true) {

        let isCommentAttachment = sourceValue is CommentAttachment || targetValue is CommentAttachment
        let isHtmlAttachment = sourceValue is HTMLAttachment || targetValue is HTMLAttachment
        let isLineAttachment = sourceValue is LineAttachment || targetValue is LineAttachment
        let isImageAttachment = sourceValue is ImageAttachment || targetValue is ImageAttachment
        let isVideoAttachment = sourceValue is VideoAttachment || targetValue is VideoAttachment

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
        case NSAttachmentAttributeName where isHtmlAttachment:
            let sourceAttachment = sourceValue as? HTMLAttachment
            let targetAttachment = targetValue as? HTMLAttachment

            processHtmlAttachmentDifferences(in: domRange, betweenOriginal: sourceAttachment, andNew: targetAttachment)
        case NSAttachmentAttributeName where isImageAttachment:
            let sourceAttachment = sourceValue as? ImageAttachment
            let targetAttachment = targetValue as? ImageAttachment

            processImageAttachmentDifferences(in: domRange, betweenOriginal: sourceAttachment, andNew: targetAttachment)
        case NSAttachmentAttributeName where isVideoAttachment:
            let sourceAttachment = sourceValue as? VideoAttachment
            let targetAttachment = targetValue as? VideoAttachment

            processVideoAttachmentDifferences(in: domRange, betweenOriginal: sourceAttachment, andNew: targetAttachment)
        case NSParagraphStyleAttributeName:
            let sourceStyle = sourceValue as? ParagraphStyle
            let targetStyle = targetValue as? ParagraphStyle

            processBlockquoteDifferences(in: domRange, betweenOriginal: sourceStyle?.blockquote, andNew: targetStyle?.blockquote)
            processListDifferences(in: domRange, betweenOriginal: sourceStyle?.textLists.last, andNew: targetStyle?.textLists.last, canMergeLeft: canMergeLeft, canMergeRight: canMergeRight)
            processHeaderDifferences(in: domRange, betweenOriginal: sourceStyle?.headerLevel, andNew: targetStyle?.headerLevel)
            processHTMLParagraphDifferences(in: domRange, betweenOriginal: sourceStyle?.htmlParagraph, andNew: targetStyle?.htmlParagraph)
        case NSLinkAttributeName:
            let sourceStyle = sourceValue as? URL
            let targetStyle = targetValue as? URL
            processLinkDifferences(in: domRange, betweenOriginal: sourceStyle, andNew: targetStyle)
        default:
            break
        }
    }

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
    private func processImageAttachmentDifferences(in range: NSRange, betweenOriginal original: ImageAttachment?, andNew new: ImageAttachment?) {

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

    /// Process difference in attachmente properties, and applies them to the DOM in the specified range
    ///
    /// - Parameters:
    ///   - range: the range in the DOM where the differences must be applied.
    ///   - original: the original attachment existing in the range if any.
    ///   - new: the new attachment to apply to the range if any.
    ///
    private func processVideoAttachmentDifferences(in range: NSRange, betweenOriginal original: VideoAttachment?, andNew new: VideoAttachment?) {
/*
        let originalUrl = original?.srcURL
        let newUrl = new?.srcURL

        let addVideoUrl = originalUrl == nil && newUrl != nil
        let removeVideoUrl = originalUrl != nil && newUrl == nil

        if addVideoUrl {
            guard let urlToAdd = newUrl else {
                assertionFailure("This should not be possible.  Review your logic.")
                return
            }

            dom.replace(range, withVideoURL: urlToAdd, posterURL: new?.posterURL)
        } else if removeVideoUrl {
            dom.removeVideo(spanning: range)
        }
 */
    }

    private func processLineAttachmentDifferences(in range: NSRange, betweenOriginal original: LineAttachment?, andNew new: LineAttachment?) {

        //dom.replaceWithHorizontalRuler(range)
    }

    private func processCommentAttachmentDifferences(in range: NSRange, betweenOriginal original: CommentAttachment?, andNew new: CommentAttachment?) {
        guard let newAttachment = new else {
            return
        }

        dom.replace(range, withComment: newAttachment.text)
    }

    private func processHtmlAttachmentDifferences(in range: NSRange, betweenOriginal original: HTMLAttachment?, andNew new: HTMLAttachment?) {
        guard let html = new?.rawHTML, original?.rawHTML != new?.rawHTML else {
            return
        }

        dom.replace(range, withRawHTML: html)
    }

    /// Processes differences in blockquote styles, and applies them to the DOM in the specified
    /// range.
    ///
    /// - Parameters:
    ///     - range: the range in the DOM where the differences must be applied.
    ///     - originalStyle: the original Blockquote object if any.
    ///     - newStyle: the new Blockquote object.
    ///
    private func processHTMLParagraphDifferences(in range: NSRange, betweenOriginal originalStyle: HTMLParagraph?, andNew newStyle: HTMLParagraph?) {

        let addStyle = originalStyle == nil && newStyle != nil
        let removeStyle = originalStyle != nil && newStyle == nil

        if addStyle {
            dom.applyHTMLParagraph(spanning: range)
        } else if removeStyle {
            dom.removeHTMLParagraph(spanning: range)
        }
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

    /// Processes differences in list styles, and applies them to the DOM in the specified
    /// range.
    ///
    /// - Parameters:
    ///     - range: the range in the DOM where the differences must be applied.
    ///     - originalStyle: the original TextList object if any.
    ///     - newStyle: the new Blockquote object.
    ///
    private func processListDifferences(in range: NSRange, betweenOriginal originalStyle: TextList?, andNew newStyle: TextList?, canMergeLeft: Bool = false, canMergeRight: Bool = false) {

        let original = originalStyle?.style
        let new = newStyle?.style

        guard original != new else {
            return
        }

        let removeOrdered = original == .ordered
        let removeUnordered = original == .unordered
        let addOrdered = new == .ordered
        let addUnordered = new == .unordered

        var rangeForAddingStyle = range

        if removeOrdered {
            rangeForAddingStyle = dom.removeOrderedList(spanning: range)
        } else if removeUnordered {
            rangeForAddingStyle = dom.removeUnorderedList(spanning: range)
        }

        if addOrdered {
            dom.applyOrderedList(spanning: rangeForAddingStyle, canMergeLeft: canMergeLeft, canMergeRight: canMergeRight)
        } else if addUnordered {
            dom.applyUnorderedList(spanning: rangeForAddingStyle, canMergeLeft: canMergeLeft, canMergeRight: canMergeRight)
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

        let addStyle = sourceHeader >= 0 && targetHeader > 0 && sourceHeader != targetHeader
        let removeStyle = sourceHeader > 0 && targetHeader >= 0 && sourceHeader != targetHeader

        if addStyle {
            dom.applyHeader(targetHeader, spanning: range)
        }
        if removeStyle {
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
    
    // MARK: - Styles: Toggling

    @discardableResult
    func toggle(formatter: AttributeFormatter, at range: NSRange) -> NSRange {
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
    func insertImage(sourceURL url: URL, atPosition position:Int, placeHolderImage: UIImage, identifier: String = UUID().uuidString) -> ImageAttachment {
        let attachment = ImageAttachment(identifier: identifier)
        attachment.delegate = self
        attachment.url = url
        attachment.image = placeHolderImage

        // Inject the Attachment and Layout
        let insertionRange = NSMakeRange(position, 0)
        let attachmentString = NSAttributedString(attachment: attachment)
        replaceCharacters(in: insertionRange, with: attachmentString)

        return attachment
    }

    /// Insert Video Element at the specified range using url as source
    ///
    /// - parameter sourceURL: the source URL of the video
    /// - parameter posterURL: an URL pointing to a frame/thumbnail of the video
    /// - parameter position: the position to insert the image
    /// - parameter placeHolderImage: an image to display while the image from sourceURL is being prepared
    ///
    /// - returns: the attachment object that was created and inserted on the text
    ///
    func insertVideo(sourceURL: URL, posterURL: URL?, atPosition position:Int, placeHolderImage: UIImage, identifier: String = UUID().uuidString) -> VideoAttachment {
        let attachment = VideoAttachment(identifier: identifier, srcURL: sourceURL, posterURL: posterURL)
        attachment.delegate = self
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
    func attachment(withId id: String) -> MediaAttachment? {
        var foundAttachment: MediaAttachment? = nil
        enumerateAttachmentsOfType(MediaAttachment.self) { (attachment, range, stop) in
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
    func update(attachment: ImageAttachment,
                alignment: ImageAttachment.Alignment,
                size: ImageAttachment.Size,
                url: URL) {
        attachment.alignment = alignment
        attachment.size = size
        attachment.url = url

        let rangesForAttachment = ranges(forAttachment:attachment)

        dom.updateImage(spanning: rangesForAttachment, url: url, size: size, alignment: alignment)
    }

    /// Updates the specified HTMLAttachment with new HTML contents
    ///
    func update(attachment: HTMLAttachment, html: String) {
        guard let range = range(for: attachment) else {
            assertionFailure("Couldn't determine the range for an Attachment")
            return
        }

        attachment.rawHTML = html

        dom.replaceCharacters(inRange: range, with: NSAttributedString(attachment: attachment))

        edited([.editedAttributes], range: range, changeInLength: 0)
/*
        let stringWithAttachment = NSAttributedString(attachment: attachment)
        replaceCharacters(in: range, with: stringWithAttachment)
 */
    }
    
    /// Removes the attachments that match the attachament identifier provided from the storage
    ///
    /// - Parameter attachmentID: the unique id of the attachment
    ///
    open func remove(attachmentID: String) {
        enumerateAttachmentsOfType(MediaAttachment.self) { (attachment, range, stop) in
            if attachment.identifier == attachmentID {
                self.replaceCharacters(in: range, with: NSAttributedString(string: ""))
                stop.pointee = true
            }
        }
    }

    /// Removes all of the TextAttachments from the storage
    ///
    open func removeMediaAttachments() {
        var ranges = [NSRange]()
        enumerateAttachmentsOfType(MediaAttachment.self) { (attachment, range, _) in
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

    open func getHTML(prettyPrint: Bool = false) -> String {
        return dom.getHTML(prettyPrint: prettyPrint)
    }

    func setHTML(_ html: String, withDefaultFontDescriptor defaultFontDescriptor: UIFontDescriptor) {
        
        let attributedString = dom.setHTML(html, withDefaultFontDescriptor: defaultFontDescriptor)
        
        let originalLength = textStore.length
        textStore = NSMutableAttributedString(attributedString: attributedString)
        textStore.enumerateAttachmentsOfType(ImageAttachment.self) { [weak self] (attachment, _, _) in
            attachment.delegate = self
        }
        textStore.enumerateAttachmentsOfType(VideoAttachment.self) { [weak self] (attachment, _, _) in
            attachment.delegate = self
        }
        textStore.enumerateAttachmentsOfType(CommentAttachment.self) { [weak self] (attachment, _, _) in
            attachment.delegate = self
        }
        textStore.enumerateAttachmentsOfType(HTMLAttachment.self) { [weak self] (attachment, _, _) in
            attachment.delegate = self
        }

        edited([.editedAttributes, .editedCharacters], range: NSRange(location: 0, length: originalLength), changeInLength: textStore.length - originalLength)
    }
}


// MARK: - TextStorage: TextAttachmentDelegate Methods
//
extension TextStorage: MediaAttachmentDelegate {

    func mediaAttachment(
        _ mediaAttachment: MediaAttachment,
        imageForURL url: URL,
        onSuccess success: @escaping (UIImage) -> (),
        onFailure failure: @escaping () -> ()) -> UIImage
    {
        assert(attachmentsDelegate != nil)
        return attachmentsDelegate.storage(self, attachment: mediaAttachment, imageFor: url, onSuccess: success, onFailure: failure)
    }
}

extension TextStorage: VideoAttachmentDelegate {

    func videoAttachment(
        _ videoAttachment: VideoAttachment,
        imageForURL url: URL,
        onSuccess success: @escaping (UIImage) -> (),
        onFailure failure: @escaping () -> ()) -> UIImage
    {
        assert(attachmentsDelegate != nil)
        return attachmentsDelegate.storage(self, attachment: videoAttachment, imageFor: url, onSuccess: success, onFailure: failure)
    }
    
}



// MARK: - TextStorage: RenderableAttachmentDelegate Methods
//
extension TextStorage: RenderableAttachmentDelegate {

    func attachment(_ attachment: NSTextAttachment, imageForSize size: CGSize) -> UIImage? {
        assert(attachmentsDelegate != nil)
        return attachmentsDelegate.storage(self, imageFor: attachment, with: size)
    }

    func attachment(_ attachment: NSTextAttachment, boundsForLineFragment fragment: CGRect) -> CGRect {
        assert(attachmentsDelegate != nil)
        return attachmentsDelegate.storage(self, boundsFor: attachment, with: fragment)
    }
}
