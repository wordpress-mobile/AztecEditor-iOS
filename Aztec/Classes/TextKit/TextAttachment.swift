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
    /// Identifier used to match this attachment with a custom UIView subclass
    ///
    fileprivate(set) open var identifier: String
    
    /// Attachment URL
    ///
    open var url: URL?
    fileprivate var lastRequestedURL: URL?

    /// Attachment Alignment
    ///
    internal(set) open var alignment: Alignment = .center {
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

    /// The color to use when drawing progress indicators
    ///
    open var progressColor: UIColor = UIColor.blue

    /// A message to display overlaid on top of the image
    ///
    open var message: NSAttributedString? {
        willSet {
            if newValue != message {
                glyphImage = nil
            }
        }
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

    fileprivate func xPosition(forContainerWidth containerWidth: CGFloat) -> Int {
        let imageWidth = onScreenWidth(containerWidth)

        switch (alignment) {
        case .center:
            return Int(floor((containerWidth - imageWidth) / 2))
        case .right:
            return Int(floor(containerWidth - imageWidth))
        default:
            return 0
        }
    }

    fileprivate func onScreenHeight(_ containerWidth: CGFloat) -> CGFloat {
        if let image = image {
            let targetWidth = onScreenWidth(containerWidth)
            let scale = targetWidth / image.size.width

            return floor(image.size.height * scale)
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
        let origin = CGPoint(x: xPosition(forContainerWidth: bounds.size.width), y: 0)
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
            UIColor(white: 1, alpha: 0.75).setFill()
            box.fill()
        }

        if let progress = progress {
            let path = UIBezierPath()
            path.move(to: CGPoint(x:origin.x, y:origin.y))
            path.addLine(to: CGPoint(x: origin.x + (size.width * CGFloat(max(0,min(progress,1)))), y: origin.y))
            path.lineWidth = 4.0
            progressColor.setStroke()
            path.stroke()
        }

        if let message = message {
            let textRect = message.boundingRect(with: size, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
            let textPosition = CGPoint(x: origin.x, y: origin.y + ((size.height-textRect.size.height) / 2) )
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
