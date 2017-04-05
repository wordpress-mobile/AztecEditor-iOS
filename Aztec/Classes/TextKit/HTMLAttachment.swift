import Foundation
import UIKit


/// HTML Attachments: Represents unknown HTML
///
open class HTMLAttachment: NSTextAttachment {

    /// Internal Cached Image
    ///
    fileprivate var glyphImage: UIImage?

    /// Delegate
    ///
    weak var delegate: RenderableAttachmentDelegate?

    /// Name of the Root "Unknown" Tag
    ///
    open var rootTagName: String = "" {
        didSet {
            glyphImage = nil
        }
    }

    /// Raw Unknown HTML to be rendered
    ///
    open var rawHTML: String = "" {
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

        guard let rootTagName = aDecoder.decodeObject(forKey: Keys.rootTagName) as? String,
            let rawHTML = aDecoder.decodeObject(forKey: Keys.rawHTML) as? String
            else {
                return
        }

        self.rootTagName = rootTagName
        self.rawHTML = rawHTML
    }


    // MARK: - NSCoder Methods

    open override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)

        aCoder.encode(rootTagName, forKey: Keys.rootTagName)
        aCoder.encode(rawHTML, forKey: Keys.rawHTML)
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
            assertionFailure("Could not determine HTML Attachment Size")
            return .zero
        }

        return bounds
    }
}


// MARK: - Private Helpers
//
private extension HTMLAttachment {

    struct Keys {
        static let rootTagName  = "rootTagName"
        static let rawHTML      = "rawHTML"
    }
}
