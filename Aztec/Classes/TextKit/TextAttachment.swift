import Foundation
import UIKit

protocol TextAttachmentImageProvider {
    func textAttachment(
        _ textAttachment: TextAttachment,
        imageForURL url: URL,
        onSuccess success: @escaping (UIImage) -> (),
        onFailure failure: @escaping () -> ()) -> UIImage
}

/// Custom text attachment.
///
open class TextAttachment: NSTextAttachment
{
    public struct Appearance {
        public var overlayColor = UIColor(white: 0.6, alpha: 0.6)

        /// The height of the progress bar for progress indicators
        public var progressHeight = CGFloat(2.0)

        /// The color to use when drawing the backkground of the progress indicators
        ///
        public var progressBackgroundColor = UIColor.cyan

        /// The color to use when drawing progress indicators
        ///
        public var progressColor = UIColor.blue

        public var imageMargin = CGFloat(10.0)
    }


    /// This property allows the global customization of appearance properties of the TextAttachment
    ///
    open static var appearance: Appearance = Appearance()

    /// Identifier used to match this attachment with a custom UIView subclass
    ///
    fileprivate(set) open var identifier: String
    
    /// Attachment URL
    ///
    open var url: URL?
    fileprivate var lastRequestedURL: URL?

    /// Attachment Alignment
    ///
    open var alignment: Alignment = .center {
        willSet {
            if newValue != alignment {
                glyphImage = nil
            }
        }
    }

    /// Attachment Size
    ///
    open var size: Size = .full {
        willSet {
            if newValue != size {
                glyphImage = nil
            }
        }
    }

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

    /// The color to use when drawing the background overlay for messages, icons, and progress
    ///
    open var overlayColor: UIColor = TextAttachment.appearance.overlayColor

    /// The height of the progress bar for progress indicators
    open var progressHeight: CGFloat = TextAttachment.appearance.progressHeight

    /// The color to use when drawing the backkground of the progress indicators
    ///
    open var progressBackgroundColor: UIColor = TextAttachment.appearance.progressBackgroundColor

    /// The color to use when drawing progress indicators
    ///
    open var progressColor: UIColor = TextAttachment.appearance.progressColor

    open var imageMargin: CGFloat = TextAttachment.appearance.imageMargin

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

    fileprivate var glyphImage: UIImage?

    var imageProvider: TextAttachmentImageProvider?
    
    var isFetchingImage: Bool = false

    /// Creates a new attachment
    ///
    /// - parameter identifier: An unique identifier for the attachment
    ///
    /// - returns: self, initilized with the identifier a with kind = .MissingImage
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
        if aDecoder.containsValue(forKey: EncodeKeys.alignment.rawValue) {
            let alignmentRaw = aDecoder.decodeInteger(forKey: EncodeKeys.alignment.rawValue)
            if let alignment = Alignment(rawValue:alignmentRaw) {
                self.alignment = alignment
            }
        }
        if aDecoder.containsValue(forKey: EncodeKeys.size.rawValue) {
            let sizeRaw = aDecoder.decodeInteger(forKey: EncodeKeys.size.rawValue)
            if let size = Size(rawValue:sizeRaw) {
                self.size = size
            }
        }
    }

    override init(data contentData: Data?, ofType uti: String?) {
        identifier = ""
        url = nil
        super.init(data: contentData, ofType: uti)
    }

    fileprivate func setupDefaultAppearance() {
        progressHeight = TextAttachment.appearance.progressHeight
        progressBackgroundColor = TextAttachment.appearance.progressBackgroundColor
        progressColor = TextAttachment.appearance.progressColor
        overlayColor = TextAttachment.appearance.overlayColor
    }

    override open func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        aCoder.encode(identifier, forKey: EncodeKeys.identifier.rawValue)
        if let url = self.url {
            aCoder.encode(url, forKey: EncodeKeys.url.rawValue)
        }
        aCoder.encode(alignment.rawValue, forKey: EncodeKeys.alignment.rawValue)
        aCoder.encode(size.rawValue, forKey: EncodeKeys.size.rawValue)
    }

    fileprivate enum EncodeKeys: String {
        case identifier
        case url
        case alignment
        case size
    }
    // MARK: - Origin calculation

    fileprivate func xPosition(forContainerWidth containerWidth: CGFloat) -> CGFloat {
        let imageWidth = onScreenWidth(containerWidth)

        switch (alignment) {
        case .center:
            return CGFloat(floor((containerWidth - imageWidth) / 2))
        case .right:
            return CGFloat(floor(containerWidth - imageWidth))
        default:
            return 0
        }
    }

    fileprivate func onScreenHeight(_ containerWidth: CGFloat) -> CGFloat {
        if let image = image {
            let targetWidth = onScreenWidth(containerWidth)
            let scale = targetWidth / image.size.width

            return floor(image.size.height * scale) + (imageMargin * 2)
        } else {
            return 0
        }
    }

    fileprivate func onScreenWidth(_ containerWidth: CGFloat) -> CGFloat {
        if let image = image {
            switch (size) {	
            case .full:
                return floor(min(image.size.width, containerWidth))
            default:
                return floor(min(min(image.size.width,size.width), containerWidth))
            }
        } else {
            return 0
        }
    }

    // MARK: - NSTextAttachmentContainer

    override open func image(forBounds imageBounds: CGRect, textContainer: NSTextContainer?, characterIndex charIndex: Int) -> UIImage? {
        
        updateImage(inTextContainer: textContainer)

        guard let image = image else {
            return nil
        }

        if let cachedImage = glyphImage, imageBounds.size.equalTo(cachedImage.size) {
            return cachedImage
        }

        glyphImage = glyph(basedOnImage:image, forBounds: imageBounds)

        return glyphImage
    }

    fileprivate func glyph(basedOnImage image:UIImage, forBounds bounds: CGRect) -> UIImage? {

        let containerWidth = bounds.size.width
        let origin = CGPoint(x: xPosition(forContainerWidth: bounds.size.width), y: imageMargin)
        let size = CGSize(width: onScreenWidth(containerWidth), height: onScreenHeight(containerWidth))

        UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0)

        image.draw(in: CGRect(origin: origin, size: size))

        if message != nil || progress != nil {
            let box = UIBezierPath()
            box.move(to: CGPoint(x:origin.x, y:origin.y))
            box.addLine(to: CGPoint(x: origin.x + size.width, y: origin.y))
            box.addLine(to: CGPoint(x: origin.x + size.width, y: origin.y + size.height))
            box.addLine(to: CGPoint(x: origin.x, y: origin.y + size.height))
            box.addLine(to: CGPoint(x: origin.x, y: origin.y))
            box.lineWidth = 2.0
            overlayColor.setFill()
            box.fill()
        }

        if let progress = progress {
            let lineY = origin.y + (progressHeight / 2.0)

            let backgroundPath = UIBezierPath()
            backgroundPath.lineWidth = progressHeight
            progressBackgroundColor.setStroke()
            backgroundPath.move(to: CGPoint(x:origin.x, y: lineY))
            backgroundPath.addLine(to: CGPoint(x: origin.x + size.width, y: lineY ))
            backgroundPath.stroke()

            let path = UIBezierPath()
            path.lineWidth = progressHeight
            progressColor.setStroke()
            path.move(to: CGPoint(x:origin.x, y: lineY))
            path.addLine(to: CGPoint(x: origin.x + (size.width * CGFloat(max(0,min(progress,1)))), y: lineY ))
            path.stroke()
        }

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

    /// Returns the "Onscreen Character Size" of the attachment range. When we're in Alignment.None,
    /// the attachment will be 'Inline', and thus, we'll return the actual Associated View Size.
    /// Otherwise, we'll always take the whole container's width.
    ///
    override open func attachmentBounds(for textContainer: NSTextContainer?, proposedLineFragment lineFrag: CGRect, glyphPosition position: CGPoint, characterIndex charIndex: Int) -> CGRect {
        
        updateImage(inTextContainer: textContainer)
        
        if image == nil {
            return CGRect.zero
        }

        let padding = textContainer?.lineFragmentPadding ?? 0
        let width = lineFrag.width - padding * 2

        return CGRect(origin: CGPoint.zero, size: CGSize(width: width, height: onScreenHeight(width)))
    }

    func updateImage(inTextContainer textContainer: NSTextContainer? = nil) {

        guard let imageProvider = imageProvider else {
            assertionFailure("This class doesn't really support not having an updater set.")
            return
        }
        
        guard let url = url, !isFetchingImage && url != lastRequestedURL else {
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
    
    fileprivate func invalidateLayout(inTextContainer textContainer: NSTextContainer?) {
        textContainer?.layoutManager?.invalidateLayoutForAttachment(self)
    }
}



/// Nested Types
///
extension TextAttachment
{
    /// Alignment
    ///
    public enum Alignment: Int {
        case none
        case left
        case center
        case right

        func htmlString() -> String {
            switch self {
                case .center:
                    return "aligncenter"
                case .left:
                    return "alignleft"
                case .right:
                    return "alignright"
                case .none:
                    return "alignnone"
            }
        }

        static let mappedValues:[String:Alignment] = [
            Alignment.none.htmlString():.none,
            Alignment.left.htmlString():.left,
            Alignment.center.htmlString():.center,
            Alignment.right.htmlString():.right
        ]

        static func fromHTML(string value:String) -> Alignment? {
            return mappedValues[value]
        }
    }

    /// Size Onscreen!
    ///
    public enum Size: Int {
        case thumbnail
        case medium
        case large
        case full

        func htmlString() -> String {
            switch self {
            case .thumbnail:
                return "size-thumbnail"
            case .medium:
                return "size-medium"
            case .large:
                return "size-large"
            case .full:
                return "size-full"
            }
        }

        static let mappedValues:[String:Size] = [
            Size.thumbnail.htmlString():.thumbnail,
            Size.medium.htmlString():.medium,
            Size.large.htmlString():.large,
            Size.full.htmlString():.full
        ]

        static func fromHTML(string value:String) -> Size? {
            return mappedValues[value]
        }

        var width: CGFloat {
            switch self {
            case .thumbnail: return Settings.thumbnail
            case .medium: return Settings.medium
            case .large: return Settings.large
            case .full: return Settings.maximum
            }
        }

        fileprivate struct Settings {
            static let thumbnail = CGFloat(135)
            static let medium = CGFloat(270)
            static let large = CGFloat(360)
            static let maximum = CGFloat.greatestFiniteMagnitude
        }
    }
}
