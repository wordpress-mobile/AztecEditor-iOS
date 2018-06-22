import Foundation
import UIKit
import Aztec

class GutenpackAttachment: NSTextAttachment, RenderableAttachment {

    /// Internal Cached Image
    ///
    fileprivate var glyphImage: UIImage?

    /// Delegate
    ///
    weak var delegate: RenderableAttachmentDelegate?


    let blockName: String
    let blockContent: String
    
    required init?(coder aDecoder: NSCoder) {
        guard let blockName = aDecoder.decodeObject(forKey: EncodingKeys.blockName) as? String,
            let blockContent = aDecoder.decodeObject(forKey: EncodingKeys.blockContent) as? String
        else {
            return nil
        }
        
        self.blockName = blockName
        self.blockContent = blockContent

        super.init(coder: aDecoder)
    }
    
    init(name: String, content: String) {
        self.blockName = name
        self.blockContent = content
        
        super.init(data: nil, ofType: nil)
    }

    override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        aCoder.encode(blockName, forKey: EncodingKeys.blockName)
        aCoder.encode(blockContent, forKey: EncodingKeys.blockContent)
    }
}

// MARK: - NSTextAttachmentContainer
extension GutenpackAttachment {
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

extension GutenpackAttachment {
    struct EncodingKeys {
        static let blockName = "blockName"
        static let blockContent = "blockContent"
    }
}
