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
    func storage(storage: TextStorage, attachment: TextAttachment, imageForURL url: NSURL, onSuccess success: (UIImage) -> (), onFailure failure: () -> ()) -> UIImage
    func storage(storage: TextStorage, missingImageForAttachment: TextAttachment) -> UIImage
    
    /// Called when an image is about to be added to the storage as an attachment, so that the
    /// delegate can specify an URL where that image is available.
    ///
    /// - Parameters:
    ///     - storage:      The storage that is requesting the image.
    ///     - image:        The image that was added to the storage.
    ///
    /// - Returns: the requested `NSURL` where the image is stored.
    ///
    func storage(storage: TextStorage, urlForImage image: UIImage) -> NSURL
}

/// Custom NSTextStorage
///
public class TextStorage: NSTextStorage {

    typealias ElementNode = Libxml2.ElementNode
    typealias TextNode = Libxml2.TextNode
    typealias RootNode = Libxml2.RootNode
    typealias StandardElementType = Libxml2.StandardElementType

    private var textStore = NSMutableAttributedString(string: "", attributes: nil)

    private var rootNode: RootNode = {
        return RootNode(children: [TextNode(text: "")])
    }()
    
    let domQueue = dispatch_queue_create("com.wordpress.domQueue", DISPATCH_QUEUE_SERIAL)
    
    // MARK: - NSTextStorage

    override public var string: String {
        return textStore.string
    }

    // MARK: - Attachments

    var attachmentsDelegate: TextStorageAttachmentsDelegate?

    public func TextAttachments() -> [TextAttachment] {
        let range = NSMakeRange(0, length)
        var attachments = [TextAttachment]()
        enumerateAttribute(NSAttachmentAttributeName, inRange: range, options: []) { (object, range, stop) in
            if let attachment = object as? TextAttachment {
                attachments.append(attachment)
            }
        }

        return attachments
    }

    public func range(forAttachment attachment: TextAttachment) -> NSRange? {

        var range: NSRange?

        textStore.enumerateAttachmentsOfType(TextAttachment.self) { (currentAttachment, currentRange, stop) in
            if attachment == currentAttachment {
                range = currentRange
                stop.memory = true
            }
        }

        return range
    }
    
    // MARK: - NSAttributedString preprocessing

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
    private func preprocessAttachments(forAttributedString attributedString: NSAttributedString) -> NSAttributedString {
        
        let fullRange = NSRange(location: 0, length: attributedString.length)
        let finalString = NSMutableAttributedString(attributedString: attributedString)
        
        attributedString.enumerateAttribute(NSAttachmentAttributeName, inRange: fullRange, options: []) { (object, range, stop) in
            
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
            
            guard !(attachment is TextAttachment) else {
                // Only replace plain NSTextAttachment objects.
                //
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

    // MARK: - Overriden Methods

    override public func attributesAtIndex(location: Int, effectiveRange range: NSRangePointer) -> [String : AnyObject] {
        return textStore.attributesAtIndex(location, effectiveRange: range)
    }

    override public func replaceCharactersInRange(range: NSRange, withString str: String) {
        
        beginEditing()
        textStore.replaceCharactersInRange(range, withString: str)
        
        edited(.EditedCharacters, range: range, changeInLength: str.characters.count - range.length)
        
        dispatch_async(domQueue) {
            self.rootNode.replaceCharacters(inRange: range, withString: str, inheritStyle: true)
        }
        endEditing()
    }
    
    override public func replaceCharactersInRange(range: NSRange, withAttributedString attrString: NSAttributedString) {
        
        // TODO: Evaluate moving this process to `Aztec.TextView.paste()`.
        //      I didn't do it with the initial implementation as it was non-trivial. (DRM)
        //
        let attrString = preprocessAttachments(forAttributedString: attrString)
        
        beginEditing()
        textStore.replaceCharactersInRange(range, withAttributedString: attrString)
        
        edited([.EditedAttributes, .EditedCharacters], range: range, changeInLength: attrString.string.characters.count - range.length)

        dispatch_async(domQueue) {
            self.rootNode.replaceCharacters(inRange: range, withString: attrString.string, inheritStyle: false)
            
            // remove all styles for the specified range here!
            
            let finalRange = NSRange(location: range.location, length: attrString.length)
            self.copyStylesToDOM(spanning: finalRange)
        }
        endEditing()
    }

    override public func setAttributes(attrs: [String : AnyObject]?, range: NSRange) {
        beginEditing()
        textStore.setAttributes(attrs, range: range)
        edited(.EditedAttributes, range: range, changeInLength: 0)
        endEditing()
    }

    // MARK: - Styles: Synchronization with DOM

    /// Copies all styles in the specified range to the DOM.
    ///
    /// - Parameters:
    ///     - range: the range from which to take the styles to copy.
    ///
    private func copyStylesToDOM(spanning range: NSRange) {

        let options = NSAttributedStringEnumerationOptions(rawValue: 0)

        textStore.enumerateAttributesInRange(range, options: options) { (attributes, range, stop) in
            // Edit attributes

            for (key, value) in attributes {
                switch (key) {
                case NSAttachmentAttributeName:
                    copyToDOM(attachmentValue: value, spanningRange: range)
                case NSFontAttributeName:
                    copyToDOM(fontAttributesSpanning: range, fromAttributeValue: value)
                case NSLinkAttributeName:
                    copyToDOM(linkAttributeSpanning: range, fromAttributeValue: value)
                case NSStrikethroughStyleAttributeName:
                    copyToDOM(strikethroughStyleSpanning: range, fromAttributeValue: value)
                case NSUnderlineStyleAttributeName:
                    copyToDOM(underlineStyleSpanning: range, fromAttributeValue: value)
                default:
                    break
                }
            }
        }
    }
    
    private func copyToDOM(attachmentValue object: AnyObject, spanningRange range: NSRange) {
        guard let attachment = object as? TextAttachment else {
            assertionFailure("We're expecting a TextAttachment object here.  preprocessStyles should've curated this.")
            return
        }
        
        copyToDOM(attachment, spanningRange: range)
    }
    
    private func copyToDOM(attachment: TextAttachment, spanningRange range: NSRange) {
        setImageURLInDOM(attachment.url, forRange: range)
    }
    
    private func copyToDOM(fontAttributesSpanning range: NSRange, fromAttributeValue value: AnyObject) {
        
        guard let font = value as? UIFont else {
            assertionFailure("Was expecting a UIFont object as the value for the font attribute.")
            return
        }
        
        copyToDOM(fontAttributesSpanning: range, fromFont: font)
    }
    
    private func copyToDOM(linkAttributeSpanning range: NSRange, fromAttributeValue value: AnyObject) {
        
        let linkURL: NSURL
        
        if let urlValue = value as? NSURL {
            linkURL = urlValue
        } else {
            guard let stringValue = value as? String,
                let stringValueURL = NSURL(string: stringValue) else {
                    assertionFailure("Was expecting a NSString or NSURL object as the value for the link attribute.")
                    return
            }
            
            linkURL = stringValueURL
        }
        
        setLinkInDOM(range, url: linkURL)
    }
    
    private func copyToDOM(fontAttributesSpanning range: NSRange, fromFont font: UIFont) {
        
        let fontTraits = font.fontDescriptor().symbolicTraits
        
        if fontTraits.contains(.TraitBold) {
            enableBoldInDOM(range)
        }
        
        if fontTraits.contains(.TraitItalic) {
            enableItalicInDOM(range)
        }
    }
    
    private func copyToDOM(strikethroughStyleSpanning range: NSRange, fromAttributeValue value: AnyObject) {
        
        guard let intValue = value as? Int else {
            assertionFailure("The strikethrough style is always expected to be an Int.")
            return
        }
        
        guard let style = NSUnderlineStyle(rawValue: intValue) else {
            assertionFailure("The strikethrough style value is not-known.")
            return
        }
        
        copyToDOM(strikethroughStyleSpanning: range, strikethroughStyle: style)
    }
    
    private func copyToDOM(strikethroughStyleSpanning range: NSRange, strikethroughStyle style: NSUnderlineStyle) {
        
        switch (style) {
        case .StyleSingle:
            enableStrikethroughInDOM(range)
        default:
            // We don't support anything more than single-line strikethrough for now
            break
        }
    }
    
    private func copyToDOM(underlineStyleSpanning range: NSRange, fromAttributeValue value: AnyObject) {
        
        guard let intValue = value as? Int else {
            assertionFailure("The underline style is always expected to be an Int.")
            return
        }
        
        guard let style = NSUnderlineStyle(rawValue: intValue) else {
            assertionFailure("The underline style value is not-known.")
            return
        }
        
        copyToDOM(underlineStyleSpanning: range, underlineStyle: style)
    }
    
    private func copyToDOM(underlineStyleSpanning range: NSRange, underlineStyle style: NSUnderlineStyle) {
        
        switch (style) {
        case .StyleSingle:
            enableUnderlineInDOM(range)
        default:
            // We don't support anything more than single-line underline for now
            break
        }
    }
    
    // MARK: - Styles: Toggling

    func toggleBold(range: NSRange) {

        let enable = !fontTrait(.TraitBold, spansRange: range)

        modifyTrait(.TraitBold, range: range, enable: enable)

        if enable {
            enableBoldInDOM(range)
        } else {
            disableBoldInDom(range)
        }
    }

    func toggleItalic(range: NSRange) {

        let enable = !fontTrait(.TraitItalic, spansRange: range)

        modifyTrait(.TraitItalic, range: range, enable: enable)

        if enable {
            enableItalicInDOM(range)
        } else {
            disableItalicInDom(range)
        }
    }

    func toggleStrikethrough(range: NSRange) {
        toggleAttribute(NSStrikethroughStyleAttributeName, value: NSUnderlineStyle.StyleSingle.rawValue, range: range, onEnable: enableStrikethroughInDOM, onDisable: disableStrikethroughInDom)
    }

    /// Toggles underline for the specified range.
    ///
    /// - Note: A better name would have been `toggleUnderline` but it was clashing with a method
    ///     in the parent class.
    ///
    /// - Note: This is a bit tricky as we can collide with a link style.  We'll want to check for
    ///     that and correct the style if necessary.
    ///
    /// - Parameters:
    ///     - range: the range to toggle the style of.
    ///
    func toggleUnderlineForRange(range: NSRange) {
        toggleAttribute(NSUnderlineStyleAttributeName, value: NSUnderlineStyle.StyleSingle.rawValue, range: range, onEnable: enableUnderlineInDOM, onDisable: disableUnderlineInDom)
    }

    func setLink(url: NSURL, forRange range: NSRange) {
        var effectiveRange = range
        if attribute(NSLinkAttributeName, atIndex: range.location, effectiveRange: &effectiveRange) != nil {
            //if there was a link there before let's remove it
            removeAttribute(NSLinkAttributeName, range: effectiveRange)
        } else {
            //if a link was not there we are just going to add it to the provided range
            effectiveRange = range
        }
        
        addAttribute(NSLinkAttributeName, value: url, range: effectiveRange)
        setLinkInDOM(effectiveRange, url: url)
    }

    func removeLink(inRange range: NSRange){
        var effectiveRange = range
        if attribute(NSLinkAttributeName, atIndex: range.location, effectiveRange: &effectiveRange) != nil {
            //if there was a link there before let's remove it
            removeAttribute(NSLinkAttributeName, range: effectiveRange)
            
            dispatch_async(domQueue) {
                self.rootNode.unwrap(range: effectiveRange, fromElementsNamed: ["a"])
            }
        }
    }

    /// Insert Image Element at the specified range using url as source
    ///
    /// - parameter url: the source URL of the image
    /// - parameter position: the position to insert the image
    /// - parameter placeHolderImage: an image to display while the image from sourceURL is being prepared
    ///
    /// - returns: the identifier of the image
    ///
    func insertImage(sourceURL url: NSURL, atPosition position:Int, placeHolderImage: UIImage) -> String {
        let attachment = TextAttachment()
        attachment.url = url
        attachment.image = placeHolderImage

        // Inject the Attachment and Layout
        let insertionRange = NSMakeRange(position, 0)
        let attachmentString = NSAttributedString(attachment: attachment)
        replaceCharactersInRange(insertionRange, withAttributedString: attachmentString)

        return attachment.identifier
    }

    // MARK: - Attachments

    public func update(attachment attachment: TextAttachment,
                                  alignment: TextAttachment.Alignment,
                                  size: TextAttachment.Size,
                                  url: NSURL) {
        attachment.alignment = alignment
        attachment.size = size
        attachment.url = url
        let rangesForAttachment = ranges(forAttachment:attachment)
        dispatch_async(domQueue) {
            for range in rangesForAttachment {
                let element = self.rootNode.lowestElementNodeWrapping(range)
                if element.name == "img" {
                    let classAttributes = alignment.htmlString() + " " + size.htmlString()
                    element.updateAttribute(named: "class", value: classAttributes)                    
                    if let sourceURLString = url.absoluteString where element.name == "img" {
                        element.updateAttribute(named: "src", value: sourceURLString)
                    }
                }
            }
        }
    }

    private func toggleAttribute(attributeName: String, value: AnyObject, range: NSRange, onEnable: (NSRange) -> Void, onDisable: (NSRange) -> Void) {

        var effectiveRange = NSRange()
        let enable = attribute(attributeName, atIndex: range.location, effectiveRange: &effectiveRange) == nil
            || !NSEqualRanges(range, effectiveRange)

        if enable {
            addAttribute(attributeName, value: value, range: range)
            onEnable(range)
        } else {
            removeAttribute(attributeName, range: range)
            onDisable(range)
        }
    }

    // MARK: - DOM

    private func disableBoldInDom(range: NSRange) {
        dispatch_async(domQueue) {
            self.rootNode.unwrap(range: range, fromElementsNamed: StandardElementType.b.equivalentNames)
        }
    }

    private func disableItalicInDom(range: NSRange) {
        dispatch_async(domQueue) {
            self.rootNode.unwrap(range: range, fromElementsNamed: StandardElementType.i.equivalentNames)
        }
    }

    private func disableStrikethroughInDom(range: NSRange) {
        dispatch_async(domQueue) {
            self.rootNode.unwrap(range: range, fromElementsNamed: StandardElementType.s.equivalentNames)
        }
    }

    private func disableUnderlineInDom(range: NSRange) {
        dispatch_async(domQueue) {
            self.rootNode.unwrap(range: range, fromElementsNamed: StandardElementType.u.equivalentNames)
        }
    }

    private func enableBoldInDOM(range: NSRange) {

        enableInDom(
            StandardElementType.b.rawValue,
            inRange: range,
            equivalentElementNames: StandardElementType.b.equivalentNames)
    }

    private func enableInDom(elementName: String, inRange range: NSRange, equivalentElementNames: [String]) {
        dispatch_async(domQueue) {
            self.rootNode.wrapChildren(
                intersectingRange: range,
                inNodeNamed: elementName,
                withAttributes: [],
                equivalentElementNames: equivalentElementNames)
        }
    }

    private func enableItalicInDOM(range: NSRange) {

        enableInDom(
            StandardElementType.i.rawValue,
            inRange: range,
            equivalentElementNames: StandardElementType.i.equivalentNames)
    }

    private func enableStrikethroughInDOM(range: NSRange) {

        enableInDom(
            StandardElementType.s.rawValue,
            inRange: range,
            equivalentElementNames:  StandardElementType.s.equivalentNames)
    }

    private func enableUnderlineInDOM(range: NSRange) {
        enableInDom(
            StandardElementType.u.rawValue,
            inRange: range,
            equivalentElementNames:  StandardElementType.u.equivalentNames)
    }
    
    private func setLinkInDOM(range: NSRange, url: NSURL) {
        dispatch_async(domQueue) {
            self.rootNode.wrapChildren(
                intersectingRange: range,
                inNodeNamed: StandardElementType.a.rawValue,
                withAttributes: [Libxml2.StringAttribute(name:"href", value: url.absoluteString!)],
                equivalentElementNames: StandardElementType.a.equivalentNames)
        }
    }
    
    private func setImageURLInDOM(imageURL: NSURL?, forRange range: NSRange) {
        
        let imageURLString = imageURL?.absoluteString ?? ""
        
        setImageURLStringInDOM(imageURLString, forRange: range)
    }
    
    private func setImageURLStringInDOM(imageURLString: String, forRange range: NSRange) {
        dispatch_async(domQueue) {
            self.rootNode.replaceCharacters(inRange: range,
                                            withNodeNamed: StandardElementType.img.rawValue,
                                            withAttributes: [Libxml2.StringAttribute(name:"src", value: imageURLString)])
        }
    }

    // MARK: - HTML Interaction

    public func getHTML() -> String {
        
        var result: String = ""
        
        dispatch_sync(domQueue) {
            let converter = Libxml2.Out.HTMLConverter()
            result = converter.convert(self.rootNode)
        }
        
        return result
    }

    func setHTML(html: String, withDefaultFontDescriptor defaultFontDescriptor: UIFontDescriptor) {
        
        let converter = HTMLToAttributedString(usingDefaultFontDescriptor: defaultFontDescriptor)
        let output: (rootNode: RootNode, attributedString: NSAttributedString)
        
        do {
            output = try converter.convert(html)
        } catch {
            fatalError("Could not convert the HTML.")
        }
        
        dispatch_sync(domQueue) {
            self.rootNode = output.rootNode
        }
        
        let originalLength = textStore.length
        textStore = NSMutableAttributedString(attributedString: output.attributedString)
        textStore.enumerateAttachmentsOfType(TextAttachment.self) { [weak self] (attachment, range, stop) in
            attachment.imageProvider = self
        }
        edited([.EditedAttributes, .EditedCharacters], range: NSRange(location: 0, length: originalLength), changeInLength: textStore.length - originalLength)
    }
}

extension TextStorage: TextAttachmentImageProvider {

    func textAttachment(textAttachment: TextAttachment,
                        imageForURL url: NSURL,
                        onSuccess success: (UIImage) -> (),
                        onFailure failure: () -> ()) -> UIImage
    {
        guard let attachmentsDelegate = attachmentsDelegate else {
            fatalError("This class doesn't really support not having an attachments delegate set.")
        }
        
        return attachmentsDelegate.storage(self, attachment: textAttachment, imageForURL: url, onSuccess: success, onFailure: failure)
    }

}

/// Convenience extension to group font trait related methods.
///
public extension TextStorage
{


    /// Checks if the specified font trait exists at the specified character index.
    ///
    /// - Parameters:
    ///     - trait: A font trait.
    ///     - index: A character index.
    ///
    /// - Returns: True if found.
    ///
    public func fontTrait(trait: UIFontDescriptorSymbolicTraits, existsAtIndex index: Int) -> Bool {
        guard let attr = attribute(NSFontAttributeName, atIndex: index, effectiveRange: nil) else {
            return false
        }
        if let font = attr as? UIFont {
            return font.fontDescriptor().symbolicTraits.contains(trait)
        }
        return false
    }


    /// Checks if the specified font trait spans the specified NSRange.
    ///
    /// - Parameters:
    ///     - trait: A font trait.
    ///     - range: The NSRange to inspect
    ///
    /// - Returns: True if the trait spans the entire range.
    ///
    public func fontTrait(trait: UIFontDescriptorSymbolicTraits, spansRange range: NSRange) -> Bool {
        var spansRange = true

        // Assume we're removing the trait. If the trait is missing anywhere in the range assign it.
        enumerateAttribute(NSFontAttributeName,
                           inRange: range,
                           options: [],
                           usingBlock: { (object: AnyObject?, range: NSRange, stop: UnsafeMutablePointer<ObjCBool>) in
                            guard let font = object as? UIFont else {
                                return
                            }
                            if !font.fontDescriptor().symbolicTraits.contains(trait) {
                                spansRange = false
                                stop.memory = true
                            }
        })

        return spansRange
    }


    /// Adds or removes the specified font trait within the specified range.
    ///
    /// - Parameters:
    ///     - trait: A font trait.
    ///     - range: The NSRange to inspect
    ///
    public func toggleFontTrait(trait: UIFontDescriptorSymbolicTraits, range: NSRange) {
        // Bail if nothing is selected
        if range.length == 0 {
            return
        }

        let enable = !fontTrait(trait, spansRange: range)

        modifyTrait(trait, range: range, enable: enable)
    }

    private func modifyTrait(trait: UIFontDescriptorSymbolicTraits, range: NSRange, enable: Bool) {

        enumerateAttribute(NSFontAttributeName,
                           inRange: range,
                           options: [],
                           usingBlock: { (object: AnyObject?, range: NSRange, stop: UnsafeMutablePointer<ObjCBool>) in
                            guard let font = object as? UIFont else {
                                return
                            }

                            var newTraits = font.fontDescriptor().symbolicTraits

                            if enable {
                                newTraits.insert(trait)
                            } else {
                                newTraits.remove(trait)
                            }

                            let descriptor = font.fontDescriptor().fontDescriptorWithSymbolicTraits(newTraits)
                            let newFont = UIFont(descriptor: descriptor!, size: font.pointSize)

                            self.beginEditing()
                            self.removeAttribute(NSFontAttributeName, range: range)
                            self.addAttribute(NSFontAttributeName, value: newFont, range: range)
                            self.endEditing()
        })
    }
}
