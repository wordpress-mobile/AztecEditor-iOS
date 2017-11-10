import Foundation
import UIKit

protocol VideoAttachmentDelegate: class {
    func videoAttachment(
        _ videoAttachment: VideoAttachment,
        imageForURL url: URL,
        onSuccess success: @escaping (UIImage) -> (),
        onFailure failure: @escaping () -> ())

    func videoAttachmentPlaceholderImageFor(attachment: VideoAttachment) -> UIImage
}

/// Custom text attachment.
///
open class VideoAttachment: MediaAttachment {

    /// Attachment video URL
    ///
    open var srcURL: URL?

    /// Video poster image to show, while the video is not played.
    ///
    open var posterURL: URL? {
        get {
            return self.url
        }

        set {
            super.updateURL(newValue)
        }
    }    
    
    /// Creates a new attachment
    ///
    /// - parameter identifier: An unique identifier for the attachment
    ///
    required public init(identifier: String, srcURL: URL? = nil, posterURL: URL? = nil) {
        self.srcURL = srcURL
        
        super.init(identifier: identifier, url: posterURL)

        self.overlayImage = Assets.playIcon
    }

    /// Required Initializer
    ///
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        if aDecoder.containsValue(forKey: EncodeKeys.srcURL.rawValue) {
            srcURL = aDecoder.decodeObject(forKey: EncodeKeys.srcURL.rawValue) as? URL
        }
    }

    /// Required Initializer
    ///
    required public init(identifier: String, url: URL?) {
        self.srcURL = nil
        super.init(identifier: identifier, url: url)
    }

    /// Required Initializer
    ///
    required public init(data contentData: Data?, ofType uti: String?) {
        super.init(data: contentData, ofType: uti)
    }

    /// An image to display overlaid on top of the media
    ///
    open override var overlayImage: UIImage? {
        set(newValue) {
            super.overlayImage = newValue ?? Assets.playIcon
        }

        get {
            return super.overlayImage
        }
    }

    // MARK: - NSCoder Support

    override open func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        if let url = self.srcURL {
            aCoder.encode(url, forKey: EncodeKeys.srcURL.rawValue)
        }
    }

    fileprivate enum EncodeKeys: String {
        case srcURL
    }


    // MARK: - Origin calculation

    override func xPosition(forContainerWidth containerWidth: CGFloat) -> CGFloat {
        let imageWidth = onScreenWidth(containerWidth)

        return CGFloat(floor((containerWidth - imageWidth) / 2))
    }

    override func onScreenHeight(_ containerWidth: CGFloat) -> CGFloat {
        if let image = image {
            let targetWidth = onScreenWidth(containerWidth)
            let scale = targetWidth / image.size.width

            return floor(image.size.height * scale) + (appearance.imageMargin * 2)
        } else {
            return 0
        }
    }

    override func onScreenWidth(_ containerWidth: CGFloat) -> CGFloat {
        if let image = image {
            return floor(min(image.size.width, containerWidth))
        } else {
            return 0
        }
    }
}


// MARK: - NSCopying
//
extension VideoAttachment {

    override public func copy(with zone: NSZone? = nil) -> Any {
        guard let clone = super.copy() as? VideoAttachment else {
            fatalError()
        }

        clone.srcURL = srcURL
        clone.posterURL = posterURL

        return clone
    }
}
