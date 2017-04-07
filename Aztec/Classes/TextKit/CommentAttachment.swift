import Foundation
import UIKit


/// Comment Attachments: Represents an HTML Comment
///
open class CommentAttachment: NSTextAttachment {

    /// Internal Cached Image
    ///
    fileprivate var glyphImage: UIImage?

    /// Delegate
    ///
    weak var delegate: RenderableAttachmentDelegate?

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

        glyphImage = delegate?.attachment(self, imageForSize: imageBounds.size)

        return glyphImage
    }

    override open func attachmentBounds(for textContainer: NSTextContainer?, proposedLineFragment lineFrag: CGRect, glyphPosition position: CGPoint, characterIndex charIndex: Int) -> CGRect {
        guard let bounds = delegate?.attachment(self, boundsForLineFragment: lineFrag) else {
            assertionFailure("Could not determine Comment Attachment Size")
            return .zero
        }

        return bounds
    }
}
