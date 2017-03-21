import Foundation
import UIKit


/// Comment Attachment's Delegate Helpers
///
protocol CommentAttachmentDelegate: class {

    /// Returns the Bounds that should be used to render the current attachment.
    ///
    /// - Parameters:
    ///     - commentAttachment: The Comment to be rendered
    ///     - fragment: Current Line Fragment Bounds
    ///
    /// - Returns: CGRect specifiying the Attachment Bounds.
    ///
    func commentAttachment(_ commentAttachment: CommentAttachment, boundsForLineFragment fragment: CGRect) -> CGRect

    /// Returns the Image Representation for a given attachment.
    ///
    /// - Parameters:
    ///     - commentAttachment: The Comment to be rendered
    ///     - size: The Canvas Size
    ///
    /// - Returns: Optional UIImage instance, representing a given comment.
    ///
    func commentAttachment(_ commentAttachment: CommentAttachment, imageForSize size: CGSize) -> UIImage?
}


/// Comment Attachments: Represents an HTML Comment
///
open class CommentAttachment: NSTextAttachment {

    /// Internal Cached Image
    ///
    fileprivate var glyphImage: UIImage?

    /// Delegate
    ///
    weak var delegate: CommentAttachmentDelegate?

    /// A message to display overlaid on top of the image
    ///
    open var text: String = "" {
        didSet {
            glyphImage = nil
        }
    }


    // MARK: - NSTextAttachmentContainer

    override open func image(forBounds imageBounds: CGRect, textContainer: NSTextContainer?, characterIndex charIndex: Int) -> UIImage? {
        if let cachedImage = glyphImage, imageBounds.size.equalTo(cachedImage.size) {
            return cachedImage
        }

        glyphImage = delegate?.commentAttachment(self, imageForSize: imageBounds.size)

        return glyphImage
    }

    override open func attachmentBounds(for textContainer: NSTextContainer?, proposedLineFragment lineFrag: CGRect, glyphPosition position: CGPoint, characterIndex charIndex: Int) -> CGRect {
        guard let bounds = delegate?.commentAttachment(self, boundsForLineFragment: lineFrag) else {
            assertionFailure("Could not determine Comment Attachment Size")
            return .zero
        }

        return bounds
    }
}
