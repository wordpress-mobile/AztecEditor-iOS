import Foundation
import UIKit


/// Custom text attachment.
///
open class ImageAttachment: MediaAttachment {

    /// Attachment's Caption String
    ///
    open var caption: NSAttributedString?

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
    open var size: Size = .none {
        willSet {
            if newValue != size {
                glyphImage = nil
            }
        }
    }


    /// Creates a new attachment
    ///
    /// - Parameters:
    ///   - identifier: An unique identifier for the attachment
    ///   - url: the url that represents the image
    ///
    required public init(identifier: String, url: URL? = nil) {
        super.init(identifier: identifier, url: url)
    }


    /// Required Initializer
    ///
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

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
        if aDecoder.containsValue(forKey: EncodeKeys.size.rawValue),
            let caption = aDecoder.decodeObject(forKey: EncodeKeys.size.rawValue) as? NSAttributedString
        {
            self.caption = caption
        }

    }

    /// Required Initializer
    ///
    required public init(data contentData: Data?, ofType uti: String?) {
        super.init(data: contentData, ofType: uti)
    }


    // MARK: - NSCoder Support

    override open func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        aCoder.encode(alignment.rawValue, forKey: EncodeKeys.alignment.rawValue)
        aCoder.encode(size.rawValue, forKey: EncodeKeys.size.rawValue)
        aCoder.encode(caption, forKey: EncodeKeys.caption.rawValue)
    }

    private enum EncodeKeys: String {
        case alignment
        case size
        case caption
    }


    // MARK: - OnScreen Metrics

    /// Returns the Attachment's Onscreen Height: should include any margins!
    ///
    override func onScreenHeight(for containerWidth: CGFloat) -> CGFloat {
        guard let captionSize = captionSize(for: containerWidth) else {
            return super.onScreenHeight(for: containerWidth)
        }

        return  appearance.imageInsets.top + imageHeight(for: containerWidth) + appearance.imageInsets.bottom +
                appearance.captionInsets.top + captionSize.height + appearance.captionInsets.bottom
    }


    // MARK: - Image Sizing + Positioning

    /// Returns the x position for the image, for the specified container width.
    ///
    override func imagePositionX(for containerWidth: CGFloat) -> CGFloat {
        let imageWidth = onScreenWidth(for: containerWidth)

        switch alignment {
        case .center:
            return CGFloat(floor((containerWidth - imageWidth) / 2))
        case .right:
            return CGFloat(floor(containerWidth - imageWidth))
        default:
            return 0
        }
    }


    /// Returns the Image Width, for the specified container width.
    ///
    override func imageWidth(for containerWidth: CGFloat) -> CGFloat {
        guard let image = image else {
            return 0
        }

        switch size {
        case .full, .none:
            return floor(min(image.size.width, containerWidth))
        default:
            return floor(min(min(image.size.width,size.width), containerWidth))
        }
    }


    /// Returns the Caption Size for the specified container width. (Or nil if there is no caption!).
    ///
    func captionSize(for containerWidth: CGFloat) -> CGSize? {
        guard let caption = caption else {
            return nil
        }

        let containerSize = CGSize(width: containerWidth, height: .greatestFiniteMagnitude)
        return caption.boundingRect(with: containerSize, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil).size
    }


    // MARK: - Drawing

    /// Draws ImageAttachment specific fields, within the specified bounds.
    ///
    override func drawCustomElements(in bounds: CGRect, mediaBounds: CGRect) {
        guard let caption = caption, let captionSize = captionSize(for: bounds.width) else {
            return
        }

        let messageY = mediaBounds.maxY + appearance.imageInsets.bottom + appearance.captionInsets.top
        let messageRect = CGRect(x: 0, y: messageY, width: bounds.width, height: captionSize.height)

        caption.draw(in: messageRect)
    }
}


// MARK: - NSCopying
//
extension ImageAttachment {

    override public func copy(with zone: NSZone? = nil) -> Any {
        guard let clone = super.copy(with: nil) as? ImageAttachment else {
            fatalError()
        }

        clone.size = size
        clone.alignment = alignment
        clone.caption = caption

        return clone
    }
}


// MARL: - Nested Types
//
extension ImageAttachment {

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
        case none

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
            case .none:
                return ""
            }
        }

        static let mappedValues:[String:Size] = [
            Size.thumbnail.htmlString():.thumbnail,
            Size.medium.htmlString():.medium,
            Size.large.htmlString():.large,
            Size.full.htmlString():.full,
            Size.none.htmlString():.none
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
            case .none: return Settings.maximum
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
