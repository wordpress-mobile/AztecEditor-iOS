import Foundation
import UIKit

/// Implemented by a class taking care of handling attachments for the storage.
///
protocol TextStorageAttachmentsDelegate {

    /// Provides images for attachments that are part of the storage
    ///
    /// - parameter storage:    The storage that is requesting the image.
    /// - parameter attachment: The attachment that is requesting the image.
    /// - parameter url:        url for the image.
    /// - parameter success:    a callback block to be invoked with the image fetched from the url.
    /// - parameter failure:    a callback block to be invoked when an error occurs when fetching the image.
    ///
    /// - returns: returns a temporary UIImage to be used while the request is happening
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
    ///     - storage:      The storage that is requesting the image.
    ///     - image:        The image that was added to the storage.
    ///
    /// - Returns: the requested `NSURL` where the image is stored.
    ///
    func storage(_ storage: TextStorage, urlForImage image: UIImage) -> URL

    /// Called when a attachment is removed from the storage.
    ///
    /// - Parameters:
    ///   - textView: The textView where the attachment was removed.
    ///   - attachmentID: The attachment identifier of the media removed.
    func storage(_ storage: TextStorage, deletedAttachmentWithID attachmentID: String);
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

    var attachmentsDelegate: TextStorageAttachmentsDelegate?

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
        
        let fullRange = NSRange(location: 0, length: attributedString.length)
        let finalString = NSMutableAttributedString(attributedString: attributedString)
        
        attributedString.enumerateAttribute(NSAttachmentAttributeName, in: fullRange, options: []) { (object, range, stop) in

            guard let object = object else {
                return
            }
            
            guard let attachmentsDelegate = attachmentsDelegate else {
                assertionFailure("This class can't really handle not having an image provider set.")
                return
            }
            
            guard let attachment = object as? NSTextAttachment else {
                assertionFailure("We expected a text attachment object.")
                return
            }
            
            guard let image = attachment.image else {
                // We only suppot image attachments for now.  All other attachment types are
                // stripped for safety.
                //
                finalString.removeAttribute(NSAttachmentAttributeName, range: range)
                return
            }
            
            if let textAttachment = attachment as? TextAttachment {
                textAttachment.imageProvider = self
                return
            }
            
            let replacementAttachment = TextAttachment()
            replacementAttachment.imageProvider = self
            replacementAttachment.image = image
            replacementAttachment.url = attachmentsDelegate.storage(self, urlForImage: image)
            
            finalString.addAttribute(NSAttachmentAttributeName, value: replacementAttachment, range: range)
        }

        return finalString
    }

    fileprivate func detectAttachmentRemoved(in range:NSRange) {
        textStore.enumerateAttachmentsOfType(TextAttachment.self, range: range) { (attachment, range, stop) in
            self.attachmentsDelegate?.storage(self, deletedAttachmentWithID: attachment.identifier)
        }
    }

    // MARK: - Overriden Methods

    override open func attributes(at location: Int, effectiveRange range: NSRangePointer?) -> [String : Any] {
        return textStore.attributes(at: location, effectiveRange: range)
    }

    override open func replaceCharacters(in range: NSRange, with str: String) {

        beginEditing()

        if mustUpdateDOM() {
            let targetDomRange = map(visualRange: range)
            dom.replaceCharacters(inRange: targetDomRange, withString: str, inheritStyle: true)
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
            let targetDomRange = map(visualRange: range)
            dom.replaceCharacters(inRange: targetDomRange, withAttributedString: preprocessedString, inheritStyle: false)
        }

        detectAttachmentRemoved(in: range)
        textStore.replaceCharacters(in: range, with: preprocessedString)
        edited([.editedAttributes, .editedCharacters], range: range, changeInLength: attrString.string.characters.count - range.length)
        
        endEditing()
    }
    
    override open func removeAttribute(_ name: String, range: NSRange) {
        super.removeAttribute(name, range: range)
    }

    override open func setAttributes(_ attrs: [String : Any]?, range: NSRange) {
        beginEditing()

        if mustUpdateDOM() {
            let domRange = map(visualRange: range)
            dom.setAttributes(attrs, range: domRange)
        }

        textStore.setAttributes(attrs, range: range)
        edited(.editedAttributes, range: range, changeInLength: 0)
        
        endEditing()
    }
    
    // MARK: - Range Mapping: Visual vs HTML
    
    private func map(visualRange: NSRange) -> NSRange {
        return textStore.map(range: visualRange, bySubtractingAttributeNamed: VisualOnlyAttributeName)
    }
    
    // MARK: - Styles: Toggling
    @discardableResult func toggle(formatter: AttributeFormatter, at range: NSRange) -> NSRange? {
        let applicationRange = formatter.applicationRange(for: range, in: self)
        if applicationRange.length == 0, !formatter.worksInEmtpyRange() {
            return applicationRange
        }
        let newSelectedRange = formatter.toggle(in: self, at: applicationRange)
        if !formatter.present(in: self, at: applicationRange.location) {
            let domRange = map(visualRange: range)
            dom.remove(element:formatter.elementType, at: domRange)
        }
        return newSelectedRange
    }

    /// Toggles blockquotes for the specified range.
    ///
    /// - Parameter range: the range to toggle the style of.
    /// - Returns: the range that was applied to.
    func toggleBlockquote(_ range: NSRange) -> NSRange? {
        let formatter = BlockquoteFormatter()
        let applicationRange = formatter.applicationRange(for: range, in: self)
        let newSelectedRange = formatter.toggle(in: self, at: range)
        if !formatter.present(in: self, at: range.location) {
            dom.removeBlockquote(spanning: applicationRange)
        }
        return newSelectedRange
    }

    func setLink(_ url: URL, forRange range: NSRange) {
        var effectiveRange = range
        if attribute(NSLinkAttributeName, at: range.location, effectiveRange: &effectiveRange) != nil {
            //if there was a link there before let's remove it
            removeAttribute(NSLinkAttributeName, range: effectiveRange)
        } else {
            //if a link was not there we are just going to add it to the provided range
            effectiveRange = range
        }
        
        addAttribute(NSLinkAttributeName, value: url, range: effectiveRange)
    }

    func removeLink(inRange range: NSRange){
        var effectiveRange = range
        if attribute(NSLinkAttributeName, at: range.location, effectiveRange: &effectiveRange) != nil {
            //if there was a link there before let's remove it
            removeAttribute(NSLinkAttributeName, range: effectiveRange)
            
            dom.removeLink(inRange: effectiveRange)
        }
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
        attachment.imageProvider = self
        attachment.url = url
        attachment.image = placeHolderImage

        // Inject the Attachment and Layout
        let insertionRange = NSMakeRange(position, 0)
        let attachmentString = NSAttributedString(attachment: attachment)
        replaceCharacters(in: insertionRange, with: attachmentString)

        return attachment
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
        textStore.enumerateAttachmentsOfType(TextAttachment.self) { [weak self] (attachment, range, stop) in
            attachment.imageProvider = self
        }
        edited([.editedAttributes, .editedCharacters], range: NSRange(location: 0, length: originalLength), changeInLength: textStore.length - originalLength)
    }
}

extension TextStorage: TextAttachmentImageProvider {

    func textAttachment(
        _ textAttachment: TextAttachment,
        imageForURL url: URL,
        onSuccess success: @escaping (UIImage) -> (),
        onFailure failure: @escaping () -> ()) -> UIImage
    {
        guard let attachmentsDelegate = attachmentsDelegate else {
            fatalError("This class doesn't really support not having an attachments delegate set.")
        }
        
        return attachmentsDelegate.storage(self, attachment: textAttachment, imageForURL: url, onSuccess: success, onFailure: failure)
    }

}
