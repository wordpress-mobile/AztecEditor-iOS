import Foundation
import UIKit


/// Implemented by a class taking care of handling attachments for the storage.
///
protocol TextStorageAttachmentsDelegate: class {

    /// Provides images for attachments that are part of the storage
    ///
    /// - Parameters:
    ///     - storage: The storage that is requesting the image.
    ///     - attachment: The attachment that is requesting the image.
    ///     - url: url for the image.
    ///     - success: Callback block to be invoked with the image fetched from the url.
    ///     - failure: Callback block to be invoked when an error occurs when fetching the image.
    ///
    func storage(
        _ storage: TextStorage,
        attachment: NSTextAttachment,
        imageFor url: URL,
        onSuccess success: @escaping (UIImage) -> (),
        onFailure failure: @escaping () -> ())

    /// Provides an image placeholder for a specified attachment.
    ///
    /// - Parameters:
    ///     - storage: The storage that is requesting the image.
    ///     - attachment: The attachment that is requesting the image.
    ///
    /// - Returns: An Image placeholder to be rendered onscreen.
    ///
    func storage(_ storage: TextStorage, placeholderFor attachment: NSTextAttachment) -> UIImage
    
    /// Called when an image is about to be added to the storage as an attachment, so that the
    /// delegate can specify an URL where that image is available.
    ///
    /// - Parameters:
    ///     - storage: The storage that is requesting the image.
    ///     - imageAttachment: The image that was added to the storage.
    ///
    /// - Returns: the requested `URL` where the image is stored, or nil if it's not yet available.
    ///
    func storage(_ storage: TextStorage, urlFor imageAttachment: ImageAttachment) -> URL?

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

    // MARK: - Storage

    fileprivate var textStore = NSMutableAttributedString(string: "", attributes: nil)
    fileprivate var textStoreString = ""


    // MARK: - Delegates

    /// NOTE:
    /// `attachmentsDelegate` is an optional property. On purpose. During a Drag and Drop OP, the
    /// LayoutManager may instantiate an entire TextKit stack. Since there is absolutely no entry point
    /// in which we may set this delegate, we need to set it as optional.
    ///
    /// Ref. https://github.com/wordpress-mobile/AztecEditor-iOS/issues/727
    ///
    weak var attachmentsDelegate: TextStorageAttachmentsDelegate?


    // MARK: - Calculated Properties

    override open var string: String {
        return textStoreString
    }

    open var mediaAttachments: [MediaAttachment] {
        let range = NSMakeRange(0, length)
        var attachments = [MediaAttachment]()
        enumerateAttribute(.attachment, in: range, options: []) { (object, range, stop) in
            if let attachment = object as? MediaAttachment {
                attachments.append(attachment)
            }
        }

        return attachments
    }


    // MARK: - Range Methods

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

        return stringWithAttachments
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
        // Ref. https://github.com/wordpress-mobile/AztecEditor-iOS/issues/727:
        // If the delegate is not set, we *Explicitly* do not want to crash here.
        //
        guard let delegate = attachmentsDelegate else {
            return attributedString
        }

        let fullRange = NSRange(location: 0, length: attributedString.length)
        let finalString = NSMutableAttributedString(attributedString: attributedString)
        
        attributedString.enumerateAttribute(.attachment, in: fullRange, options: []) { (object, range, stop) in
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
                    finalString.removeAttribute(.attachment, range: range)
                    return
                }

                let replacementAttachment = ImageAttachment(identifier: NSUUID().uuidString)
                replacementAttachment.delegate = self
                replacementAttachment.image = image

                let imageURL = delegate.storage(self, urlFor: replacementAttachment)
                replacementAttachment.updateURL(imageURL)

                finalString.addAttribute(.attachment, value: replacementAttachment, range: range)
            }
        }

        return finalString
    }

    fileprivate func detectAttachmentRemoved(in range: NSRange) {
        // Ref. https://github.com/wordpress-mobile/AztecEditor-iOS/issues/727:
        // If the delegate is not set, we *Explicitly* do not want to crash here.
        //
        guard let delegate = attachmentsDelegate else {
            return
        }

        textStore.enumerateAttachmentsOfType(MediaAttachment.self, range: range) { (attachment, range, stop) in
            delegate.storage(self, deletedAttachmentWith: attachment.identifier)
        }
    }

    // MARK: - Overriden Methods

    /// Retrieves the attributes for the requested character location.
    ///
    /// - Important: please note that this method returns the style at the character location, and
    ///     NOT at the caret location.  For N characters we always have N+1 character locations.
    ///
    override open func attributes(at location: Int, effectiveRange range: NSRangePointer?) -> [AttributedStringKey : Any] {

        guard textStore.length > 0 else {
            return [:]
        }

        return textStore.attributes(at: location, effectiveRange: range)
    }

    private func replaceTextStoreString(_ range: NSRange, with string: String) {
        let utf16String = textStoreString.utf16
        let startIndex = utf16String.index(utf16String.startIndex, offsetBy: range.location)
        let endIndex = utf16String.index(startIndex, offsetBy: range.length)
        textStoreString.replaceSubrange(startIndex..<endIndex, with: string)
    }
 
    override open func replaceCharacters(in range: NSRange, with str: String) {

        beginEditing()

        detectAttachmentRemoved(in: range)
        textStore.replaceCharacters(in: range, with: str)

        replaceTextStoreString(range, with: str)

        edited(.editedCharacters, range: range, changeInLength: str.count - range.length)
        
        endEditing()
    }

    override open func replaceCharacters(in range: NSRange, with attrString: NSAttributedString) {

        let preprocessedString = preprocessAttributesForInsertion(attrString)

        beginEditing()

        detectAttachmentRemoved(in: range)
        textStore.replaceCharacters(in: range, with: preprocessedString)

        replaceTextStoreString(range, with: attrString.string)

        edited([.editedAttributes, .editedCharacters], range: range, changeInLength: attrString.length - range.length)

        endEditing()
    }

    override open func setAttributes(_ attrs: [AttributedStringKey: Any]?, range: NSRange) {
        beginEditing()

        let fixedAttributes = ensureMatchingFontAndParagraphHeaderStyles(beforeApplying: attrs ?? [:], at: range)

        textStore.setAttributes(fixedAttributes, range: range)
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

    /// Return the range of an attachment with the specified identifier if any
    ///
    /// - Parameter attachmentID: the id of the attachment
    /// - Returns: the range of the attachment
    ///
    open func rangeFor(attachmentID: String) -> NSRange? {
        var foundRange: NSRange?
        enumerateAttachmentsOfType(MediaAttachment.self) { (attachment, range, stop) in
            if attachment.identifier == attachmentID {
                foundRange = range
                stop.pointee = true
            }
        }
        return foundRange
    }

    /// Removes all of the MediaAttachments from the storage
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

    // MARK: - HTML Interaction

    open func getHTML(serializer: HTMLSerializer) -> String {
        let parser = AttributedStringParser()
        let rootNode = parser.parse(self)

        return serializer.serialize(rootNode)

    }

    func setHTML(_ html: String,
                 defaultAttributes: [AttributedStringKey: Any],
                 postProcessingHTMLWith postProcessHTML: HTMLTreeProcessor? = nil) {

        let originalLength = textStore.length

        textStore = NSMutableAttributedString(withHTML: html,
                                              defaultAttributes: defaultAttributes,
                                              postProcessingHTMLWith: postProcessHTML)

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

        textStoreString = textStore.string

        edited([.editedAttributes, .editedCharacters], range: NSRange(location: 0, length: originalLength), changeInLength: textStore.length - originalLength)
    }
}


// MARK: - Header Font Attribute Fixes
//
private extension TextStorage {

    /// Ensures the font style is consistent with the paragraph header style that's about to be applied.
    ///
    /// - Parameters:
    ///   - attrs: NSAttributedString attributes that are about to be applied.
    ///   - range: Range that's about to be affected by the new Attributes collection.
    ///
    /// - Returns: Collection of attributes with the Font Attribute corrected, if needed.
    ///
    func ensureMatchingFontAndParagraphHeaderStyles(beforeApplying attrs: [AttributedStringKey: Any], at range: NSRange) -> [AttributedStringKey: Any] {
        let newStyle = attrs[.paragraphStyle] as? ParagraphStyle
        let oldStyle = textStore.attribute(.paragraphStyle, at: range.location, effectiveRange: nil) as? ParagraphStyle

        let newLevel = newStyle?.headers.last?.level ?? .none
        let oldLevel = oldStyle?.headers.last?.level ?? .none

        guard oldLevel != newLevel else {
            return attrs
        }
        
        return fixFontAttribute(in: attrs, headerLevel: newLevel)
    }

    /// This helper re-applies the HeaderFormatter to the specified collection of attributes, so that the Font Attribute is explicitly set,
    /// and it matches the target HeaderLevel.
    ///
    /// - Parameters:
    ///   - attrs: NSAttributedString attributes that are about to be applied.
    ///   - headerLevel: HeaderLevel specified by the ParagraphStyle, associated to the application range.
    ///
    /// - Returns: Collection of attributes with the Font Attribute corrected, so that it matches the specified HeaderLevel.
    ///
    private func fixFontAttribute(in attrs: [AttributedStringKey: Any], headerLevel: Header.HeaderType) ->  [AttributedStringKey: Any] {
        let formatter = HeaderFormatter(headerLevel: headerLevel)
        return formatter.apply(to: attrs)
    }
}


// MARK: - TextStorage: MediaAttachmentDelegate Methods
//
extension TextStorage: MediaAttachmentDelegate {

    func mediaAttachmentPlaceholder(for attachment: MediaAttachment) -> UIImage {
        guard let delegate = attachmentsDelegate else {
            fatalError()
        }

        return delegate.storage(self, placeholderFor: attachment)
    }

    func mediaAttachment(
        _ mediaAttachment: MediaAttachment,
        imageFor url: URL,
        onSuccess success: @escaping (UIImage) -> (),
        onFailure failure: @escaping () -> ())
    {
        guard let delegate = attachmentsDelegate else {
            fatalError()
        }

        delegate.storage(self, attachment: mediaAttachment, imageFor: url, onSuccess: success, onFailure: failure)
    }
}


// MARK: - TextStorage: VideoAttachmentDelegate Methods
//
extension TextStorage: VideoAttachmentDelegate {

    func videoAttachmentPlaceholderImageFor(attachment: VideoAttachment) -> UIImage {
        guard let delegate = attachmentsDelegate else {
            fatalError()
        }

        return delegate.storage(self, placeholderFor: attachment)
    }

    func videoAttachment(
        _ videoAttachment: VideoAttachment,
        imageForURL url: URL,
        onSuccess success: @escaping (UIImage) -> (),
        onFailure failure: @escaping () -> ())
    {
        guard let delegate = attachmentsDelegate else {
            fatalError()
        }

        delegate.storage(self, attachment: videoAttachment, imageFor: url, onSuccess: success, onFailure: failure)
    }
}



// MARK: - TextStorage: RenderableAttachmentDelegate Methods
//
extension TextStorage: RenderableAttachmentDelegate {

    func attachment(_ attachment: NSTextAttachment, imageForSize size: CGSize) -> UIImage? {
        guard let delegate = attachmentsDelegate else {
            fatalError()
        }

        return delegate.storage(self, imageFor: attachment, with: size)
    }

    func attachment(_ attachment: NSTextAttachment, boundsForLineFragment fragment: CGRect) -> CGRect {
        guard let delegate = attachmentsDelegate else {
            fatalError()
        }

        return delegate.storage(self, boundsFor: attachment, with: fragment)
    }
}
