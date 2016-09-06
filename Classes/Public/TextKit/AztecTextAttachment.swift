import Foundation


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

    /// Attachment Size
    ///
    public var size: Size = .Maximum

    /// Indicates the Height to be occupied onscreen
    ///
    var lineHeight = CGFloat.min


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

    /// Returns the "Onscreen Character Size". We'll always return the full width, plus, the scaled View's
    /// Height.
    ///
    public override func attachmentBoundsForTextContainer(textContainer: NSTextContainer?, proposedLineFragment lineFrag: CGRect, glyphPosition position: CGPoint, characterIndex charIndex: Int) -> CGRect {
        let characterSize = CGSizeMake(lineFrag.width, lineHeight)
        return CGRect(origin: CGPointZero, size: characterSize)
    }


    /// Returns the maximum allowed Width for a given TextContainer, considering both, container constraints
    /// and Attachment Target Size.
    ///
    func maximumWidthForContainer(textContainer: NSTextContainer) -> CGFloat {
        let maximumContainerWidth = textContainer.size.width - (2 * textContainer.lineFragmentPadding)
        return min(size.targetWidth, maximumContainerWidth)
    }
}



/// Nested Types
///
extension AztecTextAttachment
{
    /// Supported Media
    ///
    public enum Kind {
        case Image(image: UIImage)
    }

    /// Size Onscreen!
    ///
    public enum Size {
        case Thumbnail
        case Medium
        case Large
        case Maximum

        var targetWidth: CGFloat {
            switch self {
            case .Thumbnail:    return Settings.thumbnail
            case .Medium:       return Settings.medium
            case .Large:        return Settings.large
            case .Maximum:      return Settings.maximum
            }
        }

        private struct Settings {
            static let thumbnail    = CGFloat(135)
            static let medium       = CGFloat(270)
            static let large        = CGFloat(360)
            static let maximum      = CGFloat.max
        }
    }
}
