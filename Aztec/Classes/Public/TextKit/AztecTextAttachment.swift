import Foundation
import UIKit

/// Custom text attachment.
///
public class AztecTextAttachment: NSTextAttachment
{
    /// Identifier used to match this attachment with a custom UIView subclass
    ///
    private(set) public var identifier: String

    /// Attachment Kind
    ///
    public var kind: Kind?

    /// Attachment Alignment
    ///
    internal(set) public var alignment: Alignment = .Center

    /// Attachment Size
    ///
    public var size: Size = .Maximum

    /// Designed Initializer
    ///
    public init(identifier: String) {
        self.identifier = identifier
        super.init(data: nil, ofType: nil)
    }

    /// Required Initializer
    ///
    required public init?(coder aDecoder: NSCoder) {
        identifier = ""
        super.init(coder: aDecoder)
    }

    // MARK: - Origin calculation

    func xPosition(forContainerWidth containerWidth: CGFloat) -> Int {

        let imageWidth = onScreenWidth()

        switch (alignment) {
        case .Center:
            return Int(floor((containerWidth - imageWidth) / 2))
        case .Right:
            return Int(floor(containerWidth - imageWidth))
        default:
            return 0
        }
    }

    func onScreenHeight() -> CGFloat {
        if let image = image {
            let targetWidth = onScreenWidth()
            let scale = targetWidth / image.size.width

            return image.size.height * scale
        } else {
            return 0
        }
    }

    func onScreenWidth() -> CGFloat {
        if let image = image {
            switch (size) {
            case .Maximum:
                return image.size.width
            default:
                return size.width
            }
        } else {
            return 0
        }
    }

    // MARK: - NSTextAttachmentContainer

    override public func imageForBounds(imageBounds: CGRect, textContainer: NSTextContainer?, characterIndex charIndex: Int) -> UIImage? {

        var glyphImage: UIImage? = nil

        let origin = CGPoint(x: xPosition(forContainerWidth: imageBounds.size.width), y: 0)
        let size = CGSize(width: onScreenWidth(), height: onScreenHeight())

        if let image = image {
            UIGraphicsBeginImageContextWithOptions(imageBounds.size, false, 1.0)

            image.drawInRect(CGRect(origin: origin, size: size))
            glyphImage = UIGraphicsGetImageFromCurrentImageContext()

            UIGraphicsEndImageContext()
        }

        return glyphImage
    }

    /// Returns the "Onscreen Character Size" of the attachment range. When we're in Alignment.None,
    /// the attachment will be 'Inline', and thus, we'll return the actual Associated View Size.
    /// Otherwise, we'll always take the whole container's width.
    ///
    override public func attachmentBoundsForTextContainer(textContainer: NSTextContainer?, proposedLineFragment lineFrag: CGRect, glyphPosition position: CGPoint, characterIndex charIndex: Int) -> CGRect {

        let padding = textContainer?.lineFragmentPadding ?? 0
        let width = lineFrag.width - padding * 2

        return CGRect(origin: CGPointZero, size: CGSize(width: width, height: onScreenHeight()))
    }
}



/// Nested Types
///
extension AztecTextAttachment
{
    /// Alignment
    ///
    public enum Alignment {
        case None
        case Left
        case Center
        case Right
    }

    /// Supported Media
    ///
    public enum Kind {
        case MissingImage
        case RemoteImage(url: NSURL)
        case Image(image: UIImage)
    }

    /// Size Onscreen!
    ///
    public enum Size {
        case Thumbnail
        case Medium
        case Large
        case Maximum

        var width: CGFloat {
            switch self {
            case .Thumbnail: return Settings.thumbnail
            case .Medium: return Settings.medium
            case .Large: return Settings.large
            case .Maximum: return Settings.maximum
            }
        }

        private struct Settings {
            static let thumbnail = CGFloat(135)
            static let medium = CGFloat(270)
            static let large = CGFloat(360)
            static let maximum = CGFloat.max
        }
    }
}
