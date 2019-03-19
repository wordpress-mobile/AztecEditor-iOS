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

    func mediaAttachmentPlaceholder(for attachment: MediaAttachment) -> UIImage
}

// MARK: - MediaAttachment
//
open class MediaAttachment: NSTextAttachment {

    /// Default Appearance to be applied to new MediaAttachment Instances.
    ///
    public static var defaultAppearance = Appearance()

    /// Appearance associated to the current TextAttachment Instance.
    ///
    open var appearance: Appearance = defaultAppearance

    /// Attributes accessible by the user, for general purposes.
    ///
    open var extraAttributes = [Attribute]()

    /// Identifier used to match this attachment with a custom UIView subclass
    ///
    private(set) open var identifier = String()

    /// Attachment URL
    ///
    fileprivate(set) public var url: URL?

    // The url that represents the media source, by default is the source url
    public var mediaURL: URL? {
        get {
            return url;
        }
    }

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

    /// A message to display overlaid on top of the image
    ///
    open var badgeTitle: String? {
        willSet {
            if newValue != badgeTitle {
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

    /// Refresh attachment identifier
    ///
    /// - Parameter identifier: new identifier
    open func refreshIdentifier(_ identifier: String = UUID().uuidString) {
        self.identifier = identifier
    }

    // MARK: - NSCoder

    override open func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        aCoder.encode(identifier, forKey: EncodeKeys.identifier.rawValue)
        if let url = self.url {
            aCoder.encode(url, forKey: EncodeKeys.url.rawValue)
        }
    }


    // MARK: - OnScreen Metrics

    /// Returns the Attachment's Onscreen Height: should include any margins!
    ///
    func onScreenHeight(for containerWidth: CGFloat) -> CGFloat {
        return imageHeight(for: containerWidth) + appearance.imageInsets.top + appearance.imageInsets.bottom
    }

    /// Returns the Attachment's Onscreen Width: should include any margins!
    ///
    func onScreenWidth(for containerWidth: CGFloat) -> CGFloat {
        return imageWidth(for: containerWidth)
    }


    // MARK: - Image Metrics

    /// Returns the Image's Position X, for the specified container width.
    ///
    func imagePositionX(for containerWidth: CGFloat) -> CGFloat {
        return 0
    }

    /// Returns the Image Height, for the specified container width.
    ///
    func imageHeight(for containerWidth: CGFloat) -> CGFloat {
        guard let image = image else {
            return 0
        }

        let targetWidth = onScreenWidth(for: containerWidth)
        let scale = targetWidth / image.size.width

        return floor(image.size.height * scale)
    }

    /// Returns the Image Width, for the specified container width.
    ///
    func imageWidth(for containerWidth: CGFloat) -> CGFloat {
        guard let image = image else {
            return 0
        }

        return floor(min(image.size.width, containerWidth))
    }

    /// Returns the Image Bounds, for the specified container bounds.
    ///
    func imageBounds(for bounds: CGRect) -> CGRect {
        let origin = CGPoint(x: imagePositionX(for: bounds.width), y: appearance.imageInsets.top)
        let size = CGSize(width: imageWidth(for: bounds.width), height: imageHeight(for: bounds.width))

        return CGRect(origin: origin, size: size)
    }


    // MARK: - Stub Methods

    /// Draws custom elements onscreen: Subclasses should implement this method, on a need-to basis.
    ///
    func drawCustomElements(in bounds: CGRect, mediaBounds: CGRect) {
        // NO-OP
    }


    // MARK: - NSTextAttachmentContainer

    override open func image(forBounds imageBounds: CGRect, textContainer: NSTextContainer?, characterIndex charIndex: Int) -> UIImage? {

        ensureImageIsUpToDate(in: textContainer)

        guard let image = image else {
            return delegate!.mediaAttachmentPlaceholder(for: self)
        }

        if let cachedImage = glyphImage, imageBounds.size.equalTo(cachedImage.size) {
            return cachedImage
        }

        glyphImage = glyph(for:image, in: imageBounds)

        return glyphImage
    }

    /// Returns the "Onscreen Character Size" of the attachment range. When we're in Alignment.None,
    /// the attachment will be 'Inline', and thus, we'll return the actual Associated View Size.
    /// Otherwise, we'll always take the whole container's width.
    ///
    override open func attachmentBounds(for textContainer: NSTextContainer?, proposedLineFragment lineFrag: CGRect, glyphPosition position: CGPoint, characterIndex charIndex: Int) -> CGRect {

        ensureImageIsUpToDate(in: textContainer)

        if image == nil {
            return Appearance.minimumAttachmentRect
        }

        var padding = (textContainer?.lineFragmentPadding ?? 0) * 2
        if let storage = textContainer?.layoutManager?.textStorage,
            let paragraphStyle = storage.attribute(.paragraphStyle, at: charIndex, effectiveRange: nil) as? NSParagraphStyle {

            let attachmentString = storage.attributedSubstring(from: NSMakeRange(charIndex, 1)).string
            let headIndent = storage.string.isStartOfParagraph(at: attachmentString.startIndex) ? paragraphStyle.firstLineHeadIndent : paragraphStyle.headIndent

            padding += abs(paragraphStyle.tailIndent) + abs(headIndent)
        }

        let width = floor(lineFrag.width - padding)
        let size = CGSize(width: width, height: onScreenHeight(for: width))

        return CGRect(origin: CGPoint.zero, size: size)
    }
}


// MARK: - Drawing Methods
//
extension MediaAttachment {

    /// Returns the Glyph representing the current image, with all of the required add-ons already embedded:
    ///
    /// - Overlay Background: Whenever there is a message (OR) upload in progress.
    /// - Overlay Border: Whenever there is no upload in progress (OR) there is no message visible.
    /// - Overlay Image: Image to be displayed at the center of the actual attached image
    /// - OVerlay Message: Message to be displayed below the Overlay Image.
    /// - Progress Bar: Whenever there's an Upload OP running.
    ///
    func glyph(for image: UIImage, in bounds: CGRect) -> UIImage? {

        UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0)
        let mediaBounds = self.imageBounds(for: bounds)

        image.draw(in: mediaBounds)

        drawOverlayBackground(in: mediaBounds)
        drawOverlayBorder(in: mediaBounds)

        drawOverlayBadge(in: mediaBounds)

        let overlayImageSize = drawOverlayImage(in: mediaBounds)
        drawOverlayMessage(in: mediaBounds, paddingY: overlayImageSize.height)

        drawProgress(in: mediaBounds)

        // Subclass Drawing Hook: Pass along the actual container bounds
        drawCustomElements(in: bounds, mediaBounds: mediaBounds)

        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return result
    }


    /// Draws an overlay on top of the image, with a color defined by the `appearance.overlayColor` property.
    ///
    private func drawOverlayBackground(in bounds: CGRect) {
        guard message != nil || progress != nil else {
            return
        }

        let path = UIBezierPath(rect: bounds)
        appearance.overlayColor.setFill()
        path.fill()
    }


    /// Draws a border, surrounding the image. It's width will be defined by `appearance.overlayBorderWidth`, while it's color
    /// will be taken from `appearance.overlayBorderColor`.
    ///
    /// Note that the `progress` is not nil, or there's an overlay message, this border will not be rendered.
    ///
    private func drawOverlayBorder(in bounds: CGRect) {
        guard appearance.overlayBorderWidth > 0, shouldHideBorder == false, progress == nil, message != nil else {
            return
        }

        let path = UIBezierPath(rect: bounds)
        appearance.overlayBorderColor.setStroke()
        path.lineWidth = appearance.overlayBorderWidth * 2.0
        path.addClip()
        path.stroke()
    }

    /// Draws a small badge in the top left corner of the attachment, displaying `badgeTitle`.
    /// There are a number of `appearance` properties to configure the appearance of the badge.
    ///
    private func drawOverlayBadge(in bounds: CGRect) {
        guard let badgeTitle = badgeTitle,
            badgeTitle.count > 0 else {
            return
        }

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let attributedTitle = NSAttributedString(string: badgeTitle,
                                                 attributes: [.font: appearance.badgeFont,
                                                              .foregroundColor: appearance.badgeTextColor,
                                                              .paragraphStyle: paragraphStyle])

        let textRect = attributedTitle.boundingRect(with: bounds.size,
                                                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                                                    context: nil)

        typealias metrics = Constants.BadgeDefaults

        let backgroundRect = CGRect(x: bounds.origin.x + metrics.margin,
                              y: bounds.origin.y + metrics.margin,
                              width: textRect.width + (metrics.internalPadding.left + metrics.internalPadding.right),
                              height: textRect.height + (metrics.internalPadding.top + metrics.internalPadding.bottom))

        // Draw background
        let path = UIBezierPath(roundedRect: backgroundRect, cornerRadius: metrics.cornerRadius)
        appearance.badgeBackgroundColor.setFill()
        path.fill()

        // Draw title
        let titleRect = CGRect(x: backgroundRect.origin.x,
                               y: backgroundRect.origin.y + (backgroundRect.height * 0.5) - (textRect.height * 0.5),
                               width: backgroundRect.width,
                               height: textRect.height)
        attributedTitle.draw(in: titleRect)
    }

    /// Draws the overlayImage at the precise center of the Attachment's bounds.
    ///
    /// - Returns: The actual size of the overlayImage, once displayed onscreen. This size might be actually smaller than the one defined
    ///   by the actual asset, since we make sure not to render images bigger than the canvas.
    ///
    private func drawOverlayImage(in bounds: CGRect) -> CGSize {
        guard let overlayImage = overlayImage else {
            return .zero
        }

        UIColor.white.set()
        let sizeInsideBorder = CGSize(width: bounds.width - appearance.overlayBorderWidth, height: bounds.height - appearance.overlayBorderWidth)
        let resizedImage = overlayImage.resizedImageWithinRect(rectSize: sizeInsideBorder, maxImageSize: overlayImage.size, color: .white)

        let overlayOrigin = CGPoint(x: round(bounds.midX - resizedImage.size.width * 0.5),
                                    y: round(bounds.midY - resizedImage.size.height * 0.5))

        resizedImage.draw(at: overlayOrigin)

        return resizedImage.size
    }


    /// Draws the Overlay's Message below the overlayImage, at the center of the Attachment.
    ///
    private func drawOverlayMessage(in bounds: CGRect, paddingY: CGFloat) {
        guard let message = message else {
            return
        }

        let textRect = message.boundingRect(with: bounds.size, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
        var messageY = bounds.minY + (bounds.height - textRect.height) * 0.5

        if paddingY != 0 {
            messageY = bounds.minY + Constants.messageTextTopMargin + (bounds.height + paddingY) * 0.5
        }

        // Check to see if the message will fit within the image. If not, skip it.
        let messageRect = CGRect(x: bounds.minX, y: messageY, width: bounds.width, height: textRect.height)
        if messageRect.maxY < bounds.height {
            message.draw(in: messageRect)
        }
    }


    /// Draws a progress bar, at the top of the image, matching the percentage defined by the ivar `progress`.
    ///
    private func drawProgress(in bounds: CGRect) {
        guard let progress = progress else {
            return
        }

        let progressY = bounds.minY + appearance.progressHeight * 0.5
        let progressWidth = bounds.width * CGFloat(max(0, min(progress, 1)))

        let backgroundPath = UIBezierPath()
        backgroundPath.lineWidth = appearance.progressHeight
        backgroundPath.move(to: CGPoint(x: bounds.minX, y: progressY))
        backgroundPath.addLine(to: CGPoint(x: bounds.maxX, y: progressY))
        appearance.progressBackgroundColor.setStroke()
        backgroundPath.stroke()

        let progressPath = UIBezierPath()
        progressPath.lineWidth = appearance.progressHeight
        progressPath.move(to: CGPoint(x: bounds.minX, y: progressY))
        progressPath.addLine(to: CGPoint(x: bounds.minX + progressWidth, y: progressY))
        appearance.progressColor.setStroke()
        progressPath.stroke()
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
        guard let url = mediaURL else {
            return
        }

        image = delegate!.mediaAttachmentPlaceholder(for: self)
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

        struct BadgeDefaults {
            static let backgroundColor = UIColor.black.withAlphaComponent(0.6)

            static let font = UIFont.systemFont(ofSize: 14, weight: .semibold)

            static let textColor = UIColor.white

            /// Internal padding between badge title text and the edges of the badge background
            static let internalPadding = UIEdgeInsets(top: 3.0, left: 6.0, bottom: 3.0, right: 6.0)

            /// Margin between outer edges of badge and edges of media
            static let margin: CGFloat = 10.0

            static let cornerRadius: CGFloat = 6.0
        }
    }
}


// MARK: - Appearance
//
extension MediaAttachment {

    public struct Appearance {
        
        /// The minimum rect for any media attachment.
        ///
        static let minimumAttachmentRect = CGRect(x: 0, y: 0, width: 20, height: 20)

        /// The color to use when drawing the background overlay for messages, icons, and progress
        ///
        public var overlayColor = Constants.defaultOverlayColor

        /// The border width to use when drawing the background overlay for messages, icons, and progress. Defauls to 0.
        ///
        public var overlayBorderWidth = CGFloat(0.0)

        /// The color to use when drawing the background overlay border for messages, icons, and progress
        ///
        public var overlayBorderColor = Constants.defaultOverlayColor

        /// The color to use when drawing the background of the badge used to display `badgeTitle`.
        ///
        public var badgeBackgroundColor = Constants.BadgeDefaults.backgroundColor

        /// The font to use when drawing the badge used to display `badgeTitle`.
        ///
        public var badgeFont = Constants.BadgeDefaults.font

        /// The text color to use when drawing the badge used to display `badgeTitle`.
        ///
        public var badgeTextColor = Constants.BadgeDefaults.textColor

        /// The height of the progress bar for progress indicators
        ///
        public var progressHeight = CGFloat(2.0)

        /// The color to use when drawing the backkground of the progress indicators
        ///
        public var progressBackgroundColor = UIColor.cyan

        /// The color to use when drawing progress indicators
        ///
        public var progressColor = UIColor.blue

        /// The margin to apply to the images being displayed. This is to avoid that two images in a row get glued together.
        ///
        public var imageInsets = UIEdgeInsets(top: 10.0, left: 0.0, bottom: 10.0, right: 0.0)

        /// The Insets to be applied to the Caption text (if any).. Note that this property is actually used by a subclass. Revisit when possible!
        ///
        public var captionInsets = UIEdgeInsets(top: 5.0, left: 0.0, bottom: 5.0, right: 0.0)

        /// The color to use when drawing ImageAttachment's caption (if any). Note that this property is actually used by a subclass.
        /// Revisit when possible!
        ///
        public var captionColor = UIColor.darkGray
    }
}

