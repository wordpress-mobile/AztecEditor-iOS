import Foundation
import UIKit

protocol TextAttachmentImageProvider {
    func textAttachment(textAttachment: TextAttachment, imageForURL url: NSURL, onSuccess success: (UIImage) -> (), onFailure failure: () -> ()) -> UIImage
}

/// Custom text attachment.
///
public class TextAttachment: NSTextAttachment
{
    /// Identifier used to match this attachment with a custom UIView subclass
    ///
    private(set) public var identifier: String
    
    /// Attachment URL
    ///
    public var url: NSURL?
    private var lastRequestedURL: NSURL?

    /// Attachment Alignment
    ///
    internal(set) public var alignment: Alignment = .Center

    /// Attachment Size
    ///
    public var size: Size = .Maximum

    private var glyphImage: UIImage?

    var imageProvider: TextAttachmentImageProvider?
    
    var isFetchingImage: Bool = false

    /// Creates a new attachment
    ///
    /// - parameter identifier: An unique identifier for the attachment
    ///
    /// - returns: self, initilized with the identifier a with kind = .MissingImage
    ///
    required public init(identifier: String = NSUUID().UUIDString, url: NSURL? = nil) {
        self.identifier = identifier
        self.url = url
        
        super.init(data: nil, ofType: nil)
    }

    /// Required Initializer
    ///
    required public init?(coder aDecoder: NSCoder) {
        identifier = ""
        url = nil
        super.init(coder: aDecoder)
    }

    // MARK: - Origin calculation

    private func xPosition(forContainerWidth containerWidth: CGFloat) -> Int {
        let imageWidth = onScreenWidth(containerWidth)

        switch (alignment) {
        case .Center:
            return Int(floor((containerWidth - imageWidth) / 2))
        case .Right:
            return Int(floor(containerWidth - imageWidth))
        default:
            return 0
        }
    }

    private func onScreenHeight(containerWidth: CGFloat) -> CGFloat {
        if let image = image {
            let targetWidth = onScreenWidth(containerWidth)
            let scale = targetWidth / image.size.width

            return floor(image.size.height * scale)
        } else {
            return 0
        }
    }

    private func onScreenWidth(containerWidth: CGFloat) -> CGFloat {
        if let image = image {
            switch (size) {
            case .Maximum:
                return floor(min(image.size.width, containerWidth))
            default:
                return floor(min(size.width, containerWidth))
            }
        } else {
            return 0
        }
    }

    // MARK: - NSTextAttachmentContainer

    override public func imageForBounds(imageBounds: CGRect, textContainer: NSTextContainer?, characterIndex charIndex: Int) -> UIImage? {
        
        updateImage(inTextContainer: textContainer)
        
        guard let image = image else {
            return nil
        }

        if let cachedImage = glyphImage where CGSizeEqualToSize(imageBounds.size, cachedImage.size) {
            return cachedImage
        }
        let containerWidth = imageBounds.size.width
        let origin = CGPoint(x: xPosition(forContainerWidth: imageBounds.size.width), y: 0)
        let size = CGSize(width: onScreenWidth(containerWidth), height: onScreenHeight(containerWidth))
        let scale = UIScreen.mainScreen().scale

        UIGraphicsBeginImageContextWithOptions(imageBounds.size, false, scale)

        image.drawInRect(CGRect(origin: origin, size: size))
        glyphImage = UIGraphicsGetImageFromCurrentImageContext()

        UIGraphicsEndImageContext()

        return glyphImage
    }

    /// Returns the "Onscreen Character Size" of the attachment range. When we're in Alignment.None,
    /// the attachment will be 'Inline', and thus, we'll return the actual Associated View Size.
    /// Otherwise, we'll always take the whole container's width.
    ///
    override public func attachmentBoundsForTextContainer(textContainer: NSTextContainer?, proposedLineFragment lineFrag: CGRect, glyphPosition position: CGPoint, characterIndex charIndex: Int) -> CGRect {
        
        updateImage(inTextContainer: textContainer)
        
        if image == nil {
            return CGRectZero
        }

        let padding = textContainer?.lineFragmentPadding ?? 0
        let width = lineFrag.width - padding * 2

        return CGRect(origin: CGPointZero, size: CGSize(width: width, height: onScreenHeight(width)))
    }

    func updateImage(inTextContainer textContainer: NSTextContainer? = nil) {

        guard let imageProvider = imageProvider else {
            assertionFailure("This class doesn't really support not having an updater set.")
            return
        }
        
        guard let url = url where !isFetchingImage && url != lastRequestedURL else {
            return
        }
        
        isFetchingImage = true
        
        let image = imageProvider.textAttachment(self,
                                                 imageForURL: url,
                                                 onSuccess: { [weak self] (image) in
                                            
                                                    guard let strongSelf = self else {
                                                        return
                                                    }
                                                    
                                                    strongSelf.lastRequestedURL = url
                                                    strongSelf.isFetchingImage = false
                                                    strongSelf.image = image
                                                    strongSelf.invalidateLayout(inTextContainer: textContainer)
            }, onFailure: { [weak self]() in
                
                guard let strongSelf = self else {
                    return
                }
                
                strongSelf.isFetchingImage = false
                strongSelf.invalidateLayout(inTextContainer: textContainer)
            })

        if self.image == nil {
            self.image = image
        }
    }
    
    private func invalidateLayout(inTextContainer textContainer: NSTextContainer?) {
        textContainer?.layoutManager?.invalidateLayoutForAttachment(self)
    }
}



/// Nested Types
///
extension TextAttachment
{
    /// Alignment
    ///
    public enum Alignment {
        case None
        case Left
        case Center
        case Right
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
