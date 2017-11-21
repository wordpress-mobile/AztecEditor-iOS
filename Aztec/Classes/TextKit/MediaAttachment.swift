import Foundation
import UIKit


// MARK: - MediaAttachmentDelegate
//
protocol MediaAttachmentDelegate: class {
    func mediaAttachment(
        _ mediaAttachment: MediaAttachment,
        imageFor url: URL,
        onSuccess success: @escaping (UIImage) -> (),
        onFailure failure: @escaping () -> ())

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
    open var extraAttributes = [String: String]()

    /// Identifier used to match this attachment with a custom UIView subclass
    ///
    private(set) open var identifier = String()

    /// Attachment URL
    ///
    fileprivate(set) public var url: URL?

    /// Indicates if a new Asset should be retrieved, or we're current!.
    ///
    fileprivate var needsNewAsset = true

    /// Indicates if there's a download OP in progress, or not.
    ///
    fileprivate var isFetchingImage = false

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

    /// Setting this to true will always hide the border on the overlay
    ///
    open var shouldHideBorder: Bool = false {
        willSet {
            if newValue != shouldHideBorder {
                glyphImage = nil
            }
        }
    }

    /// Image to be displayed: Contains the actual Asset + the overlays (if any), embedded
    ///
    internal var glyphImage: UIImage?

    /// Attachment's Delegate
    ///
    weak var delegate: MediaAttachmentDelegate?


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
        /// Note:
        /// As unbelievable as it will sound, when de-archiving ImageAttachment, `MediaAttachment`'s
        /// super.init(coder: aDecoder)` call results in a call to`ImageAttachment.init(data, ofType)`.
        /// Which, of course, ends up being caught by MediaAttachment's `init(data, ofType)`.
        ///
        /// Bottom line, the *identifier* and *url* might end up reset, if assigned before the `super.init` call.
        /// For that reason, we've tunned things, and move those two assignments below.
        ///
        /// *Please* keep them this way. May the reviewer forgive me, since this is horrible.
        ///
        super.init(coder: aDecoder)

        identifier = aDecoder.decodeObject(forKey: EncodeKeys.identifier.rawValue) as? String ?? identifier
        url = aDecoder.decodeObject(forKey: EncodeKeys.url.rawValue) as? URL
    }

    /// Required Initializer
    ///
    override required public init(data contentData: Data?, ofType uti: String?) {
        super.init(data: contentData, ofType: uti)
    }


    // MARK: - Open Helpers

    /// Clears all overlay information that is applied to the attachment
    ///
    open func clearAllOverlays() {
        progress = nil
        message = nil
        overlayImage = nil
    }

    /// Updates the Media URL
    ///
    open func updateURL(_ newURL: URL?, refreshAsset: Bool = true) {
        guard newURL != url else {
            return
        }

        url = newURL
        retryCount = 0
        needsNewAsset = refreshAsset
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

        ensureImageIsUpToDate(in: textContainer)

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
        let size = CGSize(width: onScreenWidth(containerWidth), height: onScreenHeight(containerWidth) - appearance.imageMargin * 2)
        return CGRect(origin: origin, size: size)
    }

    private func glyph(for image: UIImage, in bounds: CGRect) -> UIImage? {

        UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0)

        let mediaBounds = self.mediaBounds(for: bounds)
        let origin = mediaBounds.origin
        let size = mediaBounds.size

        image.draw(in: mediaBounds)

        drawOverlayBackground(at: origin, size: size)
        drawOverlayBorder(at: origin, size: size)
        drawProgress(at: origin, size: size)

        var imagePadding: CGFloat = 0
        if let overlayImage = overlayImage {
            UIColor.white.set()
            let sizeInsideBorder = CGSize(width: size.width - appearance.overlayBorderWidth, height: size.height - appearance.overlayBorderWidth)
            let newImage = overlayImage.resizedImageWithinRect(rectSize: sizeInsideBorder, maxImageSize: overlayImage.size, color: UIColor.white)
            let center = CGPoint(x: round(origin.x + (size.width / 2.0)), y: round(origin.y + (size.height / 2.0)))
            newImage.draw(at: CGPoint(x: round(center.x - (newImage.size.width / 2.0)), y: round(center.y - (newImage.size.height / 2.0))))
            imagePadding += newImage.size.height
        }

        if let message = message {
            let textRect = message.boundingRect(with: size, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
            var y =  origin.y + ((size.height - textRect.height) / 2.0)
            if imagePadding != 0 {
                y = origin.y + Constants.messageTextTopMargin + ((size.height + imagePadding) / 2.0)
            }
            let textPosition = CGPoint(x: origin.x, y: y)

            // Check to see if the message will fit within the image. If not, skip it.
            if (textPosition.y + textRect.height) < mediaBounds.height {
                message.draw(in: CGRect(origin: textPosition, size: CGSize(width:size.width, height:textRect.size.height)))
            }
        }

        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result;
    }

    private func drawOverlayBackground(at origin: CGPoint, size:CGSize) {
        guard message != nil || progress != nil else {
            return
        }
        let rect = CGRect(origin: origin, size: size)
        let path = UIBezierPath(rect: rect)
        appearance.overlayColor.setFill()
        path.fill()
    }

    private func drawOverlayBorder(at origin: CGPoint, size:CGSize) {
        // Don't display the border if the border width is 0, we are force-hiding it, or message is set with no progress
        guard appearance.overlayBorderWidth > 0,
            shouldHideBorder == false,
            progress == nil && message != nil else {
                return
        }
        let rect = CGRect(origin: origin, size: size)
        let path = UIBezierPath(rect: rect)
        appearance.overlayBorderColor.setStroke()
        path.lineWidth = (appearance.overlayBorderWidth * 2.0)
        path.addClip()
        path.stroke()
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

        ensureImageIsUpToDate(in: textContainer)

        if image == nil {
            return .zero
        }

        var padding = (textContainer?.lineFragmentPadding ?? 0) * 2
        if let storage = textContainer?.layoutManager?.textStorage,
           let paragraphStyle = storage.attribute(.paragraphStyle, at: charIndex, effectiveRange: nil) as? NSParagraphStyle {
            let attachmentString = storage.attributedSubstring(from: NSMakeRange(charIndex, 1)).string
            let headIndent = storage.string.isStartOfParagraph(at: attachmentString.startIndex) ? paragraphStyle.firstLineHeadIndent : paragraphStyle.headIndent

            padding += abs(paragraphStyle.tailIndent) + abs(headIndent)
        }
        let width = floor(lineFrag.width - padding)

        let size = CGSize(width: width, height: onScreenHeight(width))

        return CGRect(origin: CGPoint.zero, size: size)
    }
}


// MARK: - Image Loading Methods
//
private extension MediaAttachment {

    /// Whenever the asset is not up to date, this helper will retrieve the latest (remote) asset.
    ///
    func ensureImageIsUpToDate(in textContainer: NSTextContainer?) {
        guard mustUpdateImage else {
            return
        }

        updateImage(in: textContainer)
    }

    /// Indicates if the asset must be updated, or not.
    ///
    private var mustUpdateImage: Bool {
        return needsNewAsset && !isFetchingImage && retryCount < Constants.maxRetryCount
    }

    /// Requests a new asset (asynchronously), and on completion, triggers a relayout cycle.
    ///
    private func updateImage(in textContainer: NSTextContainer?) {
        guard let url = url else {
            return
        }

        image = delegate!.mediaAttachmentPlaceholderImageFor(attachment: self)
        isFetchingImage = true
        retryCount += 1

        delegate!.mediaAttachment(self, imageFor: url, onSuccess: { [weak self] newImage in
            guard let `self` = self else {
                return
            }

            self.image = newImage
            self.needsNewAsset = false
            self.isFetchingImage = false
            self.invalidateLayout(in: textContainer)

        }, onFailure: { [weak self] () in
            self?.isFetchingImage = false
        })
    }

    /// Invalidates the Layout in the specified TextContainer.
    ///
    private func invalidateLayout(in textContainer: NSTextContainer?) {
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
        clone.needsNewAsset = needsNewAsset
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

        /// Top margin for message text
        ///
        static let messageTextTopMargin = CGFloat(2.0)

        /// Default color for the overlay background (dark grey with 60% alpha).
        ///
        static let defaultOverlayColor = UIColor(red: CGFloat(46.0/255.0), green: CGFloat(69.0/255.0), blue: CGFloat(83.0/255.0), alpha: 0.6)
    }
}


// MARK: - Appearance
//
extension MediaAttachment {

    public struct Appearance {

        /// The color to use when drawing the background overlay for messages, icons, and progress
        ///
        public var overlayColor = Constants.defaultOverlayColor

        /// The border width to use when drawing the background overlay for messages, icons, and progress. Defauls to 0.
        ///
        public var overlayBorderWidth = CGFloat(0.0)

        /// The color to use when drawing the background overlay border for messages, icons, and progress
        ///
        public var overlayBorderColor = Constants.defaultOverlayColor

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

