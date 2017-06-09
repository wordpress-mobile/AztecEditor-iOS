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

        detectAttachmentRemoved(in: range)
        textStore.replaceCharacters(in: range, with: str)

        edited(.editedCharacters, range: range, changeInLength: str.characters.count - range.length)
        
        endEditing()
    }

    override open func replaceCharacters(in range: NSRange, with attrString: NSAttributedString) {

        let preprocessedString = preprocessAttributesForInsertion(attrString)

        beginEditing()

        detectAttachmentRemoved(in: range)
        textStore.replaceCharacters(in: range, with: preprocessedString)
        edited([.editedAttributes, .editedCharacters], range: range, changeInLength: attrString.length - range.length)

        endEditing()
    }

    override open func setAttributes(_ attrs: [String : Any]?, range: NSRange) {
        beginEditing()

        textStore.setAttributes(attrs, range: range)
        edited(.editedAttributes, range: range, changeInLength: 0)
        
        endEditing()
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
        /*
        attachment.alignment = alignment
        attachment.size = size
        attachment.url = url
        let rangesForAttachment = ranges(forAttachment: attachment)

        let domRanges = rangesForAttachment.map { range -> NSRange in
            string.map(visualUTF16Range: range)
        }
        
        dom.updateImage(spanning: domRanges, url: url, size: size, alignment: alignment)
        */
    }

    /// Updates the specified HTMLAttachment with new HTML contents
    ///
    func update(attachment: HTMLAttachment, html: String) {
        guard let range = range(for: attachment) else {
            assertionFailure("Couldn't determine the range for an Attachment")
            return
        }

        attachment.rawHTML = html

        let stringWithAttachment = NSAttributedString(attachment: attachment)
        replaceCharacters(in: range, with: stringWithAttachment)
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
            removeAttribute(attributeName, range: range)
        }
    }

    // MARK: - HTML Interaction

    open func getHTML(prettyPrint: Bool = false) -> String {
        let converter = NSAttributedStringToNodes()
        let rootNode = converter.convert(self)

        let serializer = Libxml2.Out.HTMLConverter(prettyPrint: prettyPrint)
        return serializer.convert(rootNode)

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

    func mediaAttachmentPlaceholderImageFor(attachment: MediaAttachment) -> UIImage {
        assert(attachmentsDelegate != nil)
        return attachmentsDelegate.storage(self, missingImageFor: attachment)
    }


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
