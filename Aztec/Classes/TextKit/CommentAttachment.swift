import Foundation
import UIKit


/// Comment Attachments: Represents an HTML Comment
///
open class CommentAttachment: NSTextAttachment, RenderableAttachment {

    /// Internal Cached Image
    ///
    fileprivate var glyphImage: UIImage?

    /// Delegate
    ///
    public weak var delegate: RenderableAttachmentDelegate?

    /// A message to display overlaid on top of the image
    ///
    open var text: String = "" {
        didSet {
            glyphImage = nil
        }
    }


    // MARK: - Initializers

    init() {
        super.init(data: nil, ofType: nil)
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(data: nil, ofType: nil)

        guard let text = aDecoder.decodeObject(forKey: Keys.text) as? String else {
            return
        }

        self.text = text
    }


    // MARK: - NSCoder Methods

    open override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)

        aCoder.encode(text, forKey: Keys.text)
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


// MARK: - Private Helpers
//
private extension CommentAttachment {

    struct Keys {
        static let text = "text"
    }
}
