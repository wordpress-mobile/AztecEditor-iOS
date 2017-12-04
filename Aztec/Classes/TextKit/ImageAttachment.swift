import Foundation
import UIKit


/// Custom text attachment.
///
open class ImageAttachment: MediaAttachment {

    // MARK: - Origin calculation

    override func xPosition(forContainerWidth containerWidth: CGFloat) -> CGFloat {
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
            switch (size) {	
            case .full, .none:
                return floor(min(image.size.width, containerWidth))
            default:
                return floor(min(min(image.size.width,size.width), containerWidth))
            }
        } else {
            return 0
        }
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

        return clone
    }
}


// MARL: - Nested Types
//
extension ImageAttachment {

    /// Attachment Link URL
    ///
    open var linkURL: URL? {
        get {
            if let stringURL = extraAttributes["data_wp_link_url"], let url = URL(string: stringURL) {
                return url
            } else {
                return nil
            }
        }

        set {
            extraAttributes["data_wp_link_url"] = newValue?.absoluteString
        }
    }

    /// Attachment Alignment
    ///
    open var alignment: Alignment {
        get {
            guard let elementClass = extraAttributes["class"] else {
                return .center
            }
            let classAttributes = elementClass.components(separatedBy: " ")            
            for classAttribute in classAttributes {
                if let alignment = ImageAttachment.Alignment.fromHTML(string: classAttribute) {
                    return alignment
                }
            }
            return .center
        }

        set {
            if let elementClass = extraAttributes["class"] {
                let classAttributes = elementClass.components(separatedBy: " ")
                var attributesToRemove = [String]()
                for classAttribute in classAttributes {
                    if let _ = ImageAttachment.Alignment.fromHTML(string: classAttribute) {
                        attributesToRemove.append(classAttribute)
                    }
                }
                var otherAttributes = classAttributes.filter({ (value) -> Bool in
                    return !attributesToRemove.contains(value)
                })
                otherAttributes.append(newValue.htmlString())
                let newClassAttributes = otherAttributes.joined(separator: " ")
                if newClassAttributes.isEmpty {
                    extraAttributes.removeValue(forKey: "class")
                } else {
                    extraAttributes["class"] = newClassAttributes
                }
            } else {
                extraAttributes["class"] = newValue.htmlString()
            }
        }
    }

    /// Attachment Size
    ///
    open var size: Size {
        get {
            guard let elementClass = extraAttributes["class"] else {
                return .none
            }
            let classAttributes = elementClass.components(separatedBy: " ")
            for classAttribute in classAttributes {
                if let alignment = ImageAttachment.Size.fromHTML(string: classAttribute) {
                    return alignment
                }
            }
            return .none
        }

        set {
            if let elementClass = extraAttributes["class"] {
                let classAttributes = elementClass.components(separatedBy: " ")
                var attributesToRemove = [String]()
                for classAttribute in classAttributes {
                    if let _ = ImageAttachment.Size.fromHTML(string: classAttribute) {
                        attributesToRemove.append(classAttribute)
                    }
                }
                var otherAttributes = classAttributes.filter({ (value) -> Bool in
                    return !attributesToRemove.contains(value)
                })
                otherAttributes.append(newValue.htmlString())
                let newClassAttributes = otherAttributes.joined(separator: " ")
                if newClassAttributes.isEmpty {
                    extraAttributes.removeValue(forKey: "class")
                } else {
                    extraAttributes["class"] = newClassAttributes
                }
            } else {
                extraAttributes["class"] = newValue.htmlString()
            }
        }
    }

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
