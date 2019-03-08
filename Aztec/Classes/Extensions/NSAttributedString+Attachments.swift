import Foundation
import UIKit


// MARK: - NSAttributedString Extension for Attachments
//
extension NSAttributedString
{
    /// Indicates the Attributed String Length of a single TextAttachment
    ///
    static let lengthOfTextAttachment = NSAttributedString(attachment: NSTextAttachment()).length

    // MARK: - Initializers
    
    /// Helper Initializer: returns an Attributed String, with the specified attachment, styled with a given
    /// collection of attributes.
    ///
    public convenience init(attachment: NSTextAttachment, attributes: [NSAttributedString.Key: Any]) {
        var attributesWithAttachment = attributes
        attributesWithAttachment[.attachment] = attachment

        self.init(.textAttachment, attributes: attributesWithAttachment)
    }
    
    public convenience init(attachment: NSTextAttachment, caption: NSAttributedString, attributes: [NSAttributedString.Key: Any]) {
        let figure = Figure()
        let figcaption = Figcaption(defaultFont: UIFont.systemFont(ofSize: 14), storing: nil)
        
        let figureAttributes = attributes.appending(figure)
        let finalString = NSMutableAttributedString(attachment: attachment, attributes: figureAttributes)
        
        let mutableCaption = NSMutableAttributedString(attributedString: caption)
        mutableCaption.append(paragraphProperty: figure)
        mutableCaption.append(paragraphProperty: figcaption)
        
        let paragraphSeparator = NSAttributedString(.paragraphSeparator, attributes: [:])
        
        finalString.append(paragraphSeparator)
        finalString.append(mutableCaption)
        finalString.append(paragraphSeparator)
        
        self.init(attributedString: finalString)
    }

    /// Loads any NSTextAttachment's lazy file reference, into a UIImage instance, in memory.
    ///
    func loadLazyAttachments() {
        enumerateAttachmentsOfType(NSTextAttachment.self) { (attachment, _, _) in
            guard let data = attachment.fileWrapper?.regularFileContents else {
                return
            }

            if let mediaAttachment = attachment as? MediaAttachment {
                mediaAttachment.refreshIdentifier()
            }

            let scale = UIScreen.main.scale
            let image = UIImage(data: data, scale: scale)
            attachment.fileWrapper = nil
            attachment.image = image
        }
    }

    /// Enumerates all of the available NSTextAttachment's of the specified kind, in a given range.
    /// For each one of those elements, the specified block will be called.
    ///
    /// - Parameters:
    ///     - range: The range that should be checked. Nil wil cause the whole text to be scanned
    ///     - type: The kind of Attachment we're after
    ///     - block: Closure to be executed, for each one of the elements
    ///
    func enumerateAttachmentsOfType<T : NSTextAttachment>(_ type: T.Type, range: NSRange? = nil, block: ((T, NSRange, UnsafeMutablePointer<ObjCBool>) -> Void)) {
        let range = range ?? NSMakeRange(0, length)
        enumerateAttribute(.attachment, in: range, options: []) { (object, range, stop) in
            if let object = object as? T {
                block(object, range, stop)
            }
        }
    }

    /// Determine the character ranges for an attachment
    ///
    /// - Parameters:
    ///     - attachment: the attachment to search for
    ///
    /// - Returns: an array of ranges where the attachement can be found
    ///
    public func ranges(forAttachment attachment: NSTextAttachment) -> [NSRange] {
        let range = NSRange(location: 0, length: length)
        var attachmentRanges = [NSRange]()
        enumerateAttribute(.attachment, in: range, options: []) { (value, effectiveRange, nil) in
            guard let foundAttachment = value as? NSTextAttachment, foundAttachment == attachment else {
                return
            }
            attachmentRanges.append(effectiveRange)
        }

        return attachmentRanges
    }

    // MARK: - Captions
    
    open func caption(for attachment: NSTextAttachment) -> NSAttributedString? {
        guard let captionRange = self.captionRange(for: attachment) else {
            return nil
        }
        
        let string = attributedSubstring(from: captionRange).mutableCopy() as! NSMutableAttributedString
        
        for character in Character.paragraphBreakingCharacters {
            string.replaceOcurrences(of: String(character), with: "")
        }
        
        return NSAttributedString(attributedString: string)
    }

    public func captionRange(for attachment: NSTextAttachment) -> NSRange? {
        guard let figureRange = self.figureRange(for: attachment) else {
            return nil
        }
        
        return figcaptionRanges(within: figureRange).first
    }

    // MARK: - Captions: Figure and Figcaption property ranges

    private func figcaptionRanges(within range: NSRange) -> [NSRange] {
        var ranges = [NSRange]()
        
        enumerateParagraphRanges(spanning: range) { (_, enclosingRange) in
            guard let paragraphStyle = attribute(.paragraphStyle, at: enclosingRange.lowerBound, effectiveRange: nil) as? ParagraphStyle else {
                return
            }
            
            if paragraphStyle.hasProperty(where: { $0 is Figcaption }) {
                ranges.append(enclosingRange)
            }
        }
        
        return ranges
    }

    private func figureRange(for attachment: NSTextAttachment) -> NSRange? {
        guard let attachmentRange = ranges(forAttachment: attachment).first else {
            return nil
        }
        
        let paragraphRange = self.paragraphRange(for: attachmentRange)

        guard let paragraphStyle = self.attribute(.paragraphStyle, at: paragraphRange.lowerBound, effectiveRange: nil) as? ParagraphStyle,
            let figure = paragraphStyle.property(where: { $0 is Figure }) as? Figure else {
                return nil
        }

        return self.paragraphRange(around: attachmentRange) { (properties) -> Bool in
            return properties.contains { $0 === figure }
        }
    }
}
