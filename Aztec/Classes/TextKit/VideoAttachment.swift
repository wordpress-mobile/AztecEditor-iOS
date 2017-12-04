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

    /// Creates a new attachment
    ///
    /// - parameter identifier: An unique identifier for the attachment
    ///
    required public init(identifier: String, srcURL: URL? = nil, posterURL: URL? = nil) {
        super.init(identifier: identifier)
        self.src = srcURL
        self.poster = posterURL
        self.overlayImage = Assets.playIcon
    }

    /// Required Initializer
    ///
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    /// Required Initializer
    ///
    required public init(identifier: String) {
        super.init(identifier: identifier)
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

    open var poster: URL? {
        get {
            return url
        }

        set {
            extraAttributes["poster"] = newValue?.absoluteString
            updateURL(newValue)
        }
    }

    open var src: URL? {
        get {
            if let src = extraAttributes["src"] {
                return URL(string: src)
            } else {
                return nil
            }
        }

        set {
            extraAttributes["src"] = newValue?.absoluteString
        }
    }
}
