import Foundation
import UIKit


// MARK: - MediaAttachmentDelegate
//
protocol MediaAttachmentDelegate: class {
    func mediaAttachment(
        _ mediaAttachment: MediaAttachment,
        imageFor url: URL,
        onCompletion completion: @escaping (UIImage?) -> ())

    func mediaAttachmentPlaceholderImageFor(attachment: MediaAttachment) -> UIImage
}

// MARK: - MediaAttachment
//
open class MediaAttachment: NSTextAttachment {

    /// Default Appearance to be applied to new MediaAttachment Instances.
    ///
    open static var defaultAppearance = Appearance()

    /// Appearance associated to the current TextAttachment Instance.
    ///
    open var appearance: Appearance = defaultAppearance

    /// Attributes accessible by the user, for general purposes.
    ///
    public var extraAttributes = [String: String]()

    /// Identifier used to match this attachment with a custom UIView subclass
    ///
    private(set) open var identifier: String
    
    /// Attachment URL
    ///
    public var url: URL? {
        didSet {
            retryCount = 0
        }
    }

    /// URL of the last successfully acquired asset
    ///
    fileprivate(set) var lastRequestedURL: URL?

    /// Number of times we've tried to download the remote asset
    ///
    fileprivate var retryCount = 0

    /// A progress value that indicates the progress of an attachment. It can be set between values 0 and 1
    ///
    open var progress: Double? = nil {
        willSet {
            assert(newValue == nil || (newValue! >= 0 && newValue! <= 1), "Progress must be value between 0 and 1 or nil")
            if newValue != progress {
                glyphImage = nil
            }
        }
    }

    /// A message to display overlaid on top of the image
    ///
    open var message: NSAttributedString? {
        willSet {
            if newValue != message {
                glyphImage = nil
            }
        }
    }

    /// An image to display overlaid on top of the image has an action icon.
    ///
    open var overlayImage: UIImage? {
        willSet {
            if newValue != overlayImage {
                glyphImage = nil
            }
        }
    }

    /// Clears all overlay information that is applied to the attachment
    ///
    open func clearAllOverlays() {
        progress = nil
        message = nil
        overlayImage = nil
    }

    /// Image to be displayed: Contains the actual Asset + the overlays (if any), embedded
    ///
    internal var glyphImage: UIImage?

    /// Attachment's Delegate
    ///
    weak var delegate: MediaAttachmentDelegate?

    /// Indicates if there's a download OP in progress, or not.
    ///
    fileprivate var isFetchingImage = false


    // MARK: - Initializers

    /// Creates a new attachment
    ///
    /// - Parameters:
    ///   - identifier: An unique identifier for the attachment
    ///   - url: the url that represents the image
    ///
    required public init(identifier: String, url: URL? = nil) {
        self.identifier = identifier
        self.url = url

        super.init(data: nil, ofType: nil)
    }

    /// Required Initializer
    ///
    required public init?(coder aDecoder: NSCoder) {
        identifier = ""

        super.init(coder: aDecoder)

        if let decodedIndentifier = aDecoder.decodeObject(forKey: EncodeKeys.identifier.rawValue) as? String {
            identifier = decodedIndentifier
        }
        if aDecoder.containsValue(forKey: EncodeKeys.url.rawValue) {
            url = aDecoder.decodeObject(forKey: EncodeKeys.url.rawValue) as? URL
        }
    }

    override required public init(data contentData: Data?, ofType uti: String?) {
        identifier = ""
        url = nil

        super.init(data: contentData, ofType: uti)
    }


    // MARK: - NSCoder

    override open func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        aCoder.encode(identifier, forKey: EncodeKeys.identifier.rawValue)
        if let url = self.url {
            aCoder.encode(url, forKey: EncodeKeys.url.rawValue)
        }
    }


    // MARK: - Position and size calculation

    func xPosition(forContainerWidth containerWidth: CGFloat) -> CGFloat {
        return 0
    }

    func onScreenHeight(_ containerWidth: CGFloat) -> CGFloat {
        guard let image = image else {
            return 0
        }

        let targetWidth = onScreenWidth(containerWidth)
        let scale = targetWidth / image.size.width

        return floor(image.size.height * scale) + (appearance.imageMargin * 2)
    }

    func onScreenWidth(_ containerWidth: CGFloat) -> CGFloat {
        guard let image = image else {
            return 0
        }

        return floor(min(image.size.width, containerWidth))
    }


    // MARK: - NSTextAttachmentContainer

    override open func image(forBounds imageBounds: CGRect, textContainer: NSTextContainer?, characterIndex charIndex: Int) -> UIImage? {
        
        updateImage(in: textContainer)

        guard let image = image else {
            return delegate!.mediaAttachmentPlaceholderImageFor(attachment: self)
        }

        if let cachedImage = glyphImage, imageBounds.size.equalTo(cachedImage.size) {
            return cachedImage
        }

        glyphImage = glyph(for:image, in: imageBounds)

        return glyphImage
    }

    func mediaBounds(for bounds: CGRect) -> CGRect {
        let containerWidth = bounds.size.width
        let origin = CGPoint(x: xPosition(forContainerWidth: bounds.size.width), y: appearance.imageMargin)
        let size = CGSize(width: onScreenWidth(containerWidth), height: onScreenHeight(containerWidth) - appearance.imageMargin)
        return CGRect(origin: origin, size: size)
    }

    private func glyph(for image: UIImage, in bounds: CGRect) -> UIImage? {

        UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0)

        let mediaBounds = self.mediaBounds(for: bounds)
        let origin = mediaBounds.origin
        let size = mediaBounds.size

        image.draw(in: mediaBounds)

        drawOverlayBackground(at: origin, size: size)
        drawProgress(at: origin, size: size)

        var imagePadding: CGFloat = 0
        if let overlayImage = overlayImage {
            UIColor.white.set()
            let center = CGPoint(x: round(origin.x + (size.width / 2.0)), y: round(origin.y + (size.height / 2.0)))
            let radius = round(overlayImage.size.width * 2.0/3.0)
            let path = UIBezierPath(arcCenter: center, radius: radius, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: true)
            path.stroke()
            overlayImage.draw(at: CGPoint(x: round(center.x - (overlayImage.size.width / 2.0)), y: round(center.y - (overlayImage.size.height / 2.0))))
            imagePadding += radius * 2;
        }

        if let message = message {
            let textRect = message.boundingRect(with: size, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
            var y =  origin.y + ((size.height - textRect.height) / 2.0)
            if imagePadding != 0 {
                y = origin.y + ((size.height + imagePadding) / 2.0)
            }
            let textPosition = CGPoint(x: origin.x, y: y)
            message.draw(in: CGRect(origin: textPosition , size: CGSize(width:size.width, height:textRect.size.height)))
        }

        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result;
    }

    private func drawOverlayBackground(at origin: CGPoint, size:CGSize) {
        guard message != nil || progress != nil else {
            return
        }

        let box = UIBezierPath()
        box.move(to: CGPoint(x:origin.x, y:origin.y))
        box.addLine(to: CGPoint(x: origin.x + size.width, y: origin.y))
        box.addLine(to: CGPoint(x: origin.x + size.width, y: origin.y + size.height))
        box.addLine(to: CGPoint(x: origin.x, y: origin.y + size.height))
        box.addLine(to: CGPoint(x: origin.x, y: origin.y))
        box.lineWidth = 2.0
        appearance.overlayColor.setFill()
        box.fill()
    }

    private func drawProgress(at origin: CGPoint, size:CGSize) {
        guard let progress = progress else {
            return
        }
        let lineY = origin.y + (appearance.progressHeight / 2.0)

        let backgroundPath = UIBezierPath()
        backgroundPath.lineWidth = appearance.progressHeight
        appearance.progressBackgroundColor.setStroke()
        backgroundPath.move(to: CGPoint(x:origin.x, y: lineY))
        backgroundPath.addLine(to: CGPoint(x: origin.x + size.width, y: lineY ))
        backgroundPath.stroke()

        let path = UIBezierPath()
        path.lineWidth = appearance.progressHeight
        appearance.progressColor.setStroke()
        path.move(to: CGPoint(x:origin.x, y: lineY))
        path.addLine(to: CGPoint(x: origin.x + (size.width * CGFloat(max(0,min(progress,1)))), y: lineY ))
        path.stroke()
    }

    /// Returns the "Onscreen Character Size" of the attachment range. When we're in Alignment.None,
    /// the attachment will be 'Inline', and thus, we'll return the actual Associated View Size.
    /// Otherwise, we'll always take the whole container's width.
    ///
    override open func attachmentBounds(for textContainer: NSTextContainer?, proposedLineFragment lineFrag: CGRect, glyphPosition position: CGPoint, characterIndex charIndex: Int) -> CGRect {
        
        updateImage(in: textContainer)
        
        if image == nil {
            return .zero
        }

        var padding = (textContainer?.lineFragmentPadding ?? 0)
        if let storage = textContainer?.layoutManager?.textStorage,
           let paragraphStyle = storage.attribute(NSParagraphStyleAttributeName, at: charIndex, effectiveRange: nil) as? NSParagraphStyle {
            padding += paragraphStyle.firstLineHeadIndent + paragraphStyle.tailIndent
        }
        let width = floor(lineFrag.width - (padding * 2))

        let size = CGSize(width: width, height: onScreenHeight(width))
        
        return CGRect(origin: CGPoint.zero, size: size)
    }
}


// MARK: - Private Methods
//
private extension MediaAttachment {

    func updateImage(in textContainer: NSTextContainer? = nil) {

        guard let delegate = delegate else {
            assertionFailure("This class doesn't really support not having an updater set.")
            return
        }

        guard !isFetchingImage && url != lastRequestedURL && retryCount < Constants.maxRetryCount else {
            return
        }

        self.image = delegate.mediaAttachmentPlaceholderImageFor(attachment: self)

        guard let url = url else {
            return
        }

        isFetchingImage = true
        retryCount += 1

        delegate.mediaAttachment(self, imageFor: url, onSuccess: { [weak self] image in
                guard let strongSelf = self else {
                    return
                }
                strongSelf.lastRequestedURL = url
                strongSelf.isFetchingImage = false
                strongSelf.image = image
                strongSelf.invalidateLayout(in: textContainer)
            }, onFailure: { [weak self] _ in
                
                guard let strongSelf = self else {
                    return
                }
                
                strongSelf.isFetchingImage = false
                strongSelf.lastRequestedURL = nil
                strongSelf.invalidateLayout(in: textContainer)
            })
    }
    
    func invalidateLayout(in textContainer: NSTextContainer?) {
        textContainer?.layoutManager?.invalidateLayout(for: self)
    }
}


// MARK: - NSCopying
//
extension MediaAttachment: NSCopying {

    public func copy(with zone: NSZone? = nil) -> Any {
        let clone = type(of: self).init(identifier: identifier, url: url)
        clone.image = image
        clone.extraAttributes = extraAttributes
        clone.url = url
        clone.lastRequestedURL = lastRequestedURL
        clone.appearance = appearance
        clone.delegate = delegate
        return clone
    }
}


// MARK: - Nested Types (Private!)
//
private extension MediaAttachment {

    /// NSCoder Keys
    ///
    enum EncodeKeys: String {
        case identifier
        case url
    }

    /// Constants
    ///
    struct Constants {
        /// Maximum number of times to retry downloading the asset, upon error
        ///
        static let maxRetryCount = 3
    }
}


// MARK: - Appearance
//
extension MediaAttachment {

    public struct Appearance {

        /// The color to use when drawing the background overlay for messages, icons, and progress
        ///
        public var overlayColor = UIColor(white: 0.6, alpha: 0.6)

        /// The height of the progress bar for progress indicators
        ///
        public var progressHeight = CGFloat(2.0)

        /// The color to use when drawing the backkground of the progress indicators
        ///
        public var progressBackgroundColor = UIColor.cyan

        /// The color to use when drawing progress indicators
        ///
        public var progressColor = UIColor.blue

        /// The margin apply to the images being displayed. This is to avoid that two images in a row get
        /// glued together.
        ///
        public var imageMargin = CGFloat(10.0)
    }
}
