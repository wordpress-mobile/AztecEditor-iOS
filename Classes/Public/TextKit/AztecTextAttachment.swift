import Foundation


/// Custom text attachment.
///
public class AztecTextAttachment: NSTextAttachment
{
    /// Supported Types
    ///
    public enum Kind {
        case Image(image: UIImage)
    }

    /// Wrapping Options. Analog to what Apple Pages does!
    ///
    public enum TextWrapping {
        case Around
        case AboveAndBelow
    }

    /// Identifier used to match this attachment with a custom UIView subclass
    ///
    private(set) public var identifier: String

    /// Attachment Kind
    ///
    public var kind: Kind?

    /// Wrapping Mode
    ///
    public var textWrapping = TextWrapping.AboveAndBelow


    /// Designed Initializer
    ///
    public init(identifier: String) {
        self.identifier = identifier
        super.init(data: nil, ofType: nil)
    }

    required public init?(coder aDecoder: NSCoder) {
        identifier = ""
        super.init(coder: aDecoder)
    }


    /// Overriden Methods
    ///
    public override func attachmentBoundsForTextContainer(textContainer: NSTextContainer?, proposedLineFragment lineFrag: CGRect, glyphPosition position: CGPoint, characterIndex charIndex: Int) -> CGRect {
        switch textWrapping {
        case .AboveAndBelow:
            return aboveAndBelowBoundsForTextContainer(textContainer, proposedLineFragment: lineFrag, glyphPosition: position)
        case .Around:
            return super.attachmentBoundsForTextContainer(textContainer, proposedLineFragment: lineFrag, glyphPosition: position, characterIndex: charIndex)
        }
    }

    private func aboveAndBelowBoundsForTextContainer(textContainer: NSTextContainer?, proposedLineFragment lineFrag: CGRect, glyphPosition position: CGPoint) -> CGRect {
        let width = (lineFrag.width - position.x) - (textContainer!.lineFragmentPadding * 2.0)
        let rect = CGRectMake(0.0, 0.0, floor(width), 1.0)
        
        return rect
    }
}
