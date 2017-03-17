import Foundation
import UIKit

/// Custom text attachment.
///
open class MoreAttachment: NSTextAttachment
{
    fileprivate var glyphImage: UIImage?

    /// The color to use when drawing progress indicators
    ///
    open var color: UIColor = UIColor.gray

    /// A message to display overlaid on top of the image
    ///
    open var label: NSAttributedString = NSAttributedString(string: "MORE") {
        willSet {
            if newValue != label {
                glyphImage = nil
            }
        }
    }

    /// Comment's Text.
    /// This is a temporary helper property, and will be removed as soon as we merge MoreAttachment + CommentAttachment.
    ///
    let text = "more"


    open var message: String = ""

    // MARK: - NSTextAttachmentContainer

    override open func image(forBounds imageBounds: CGRect, textContainer: NSTextContainer?, characterIndex charIndex: Int) -> UIImage? {

        if let cachedImage = glyphImage, imageBounds.size.equalTo(cachedImage.size) {
            return cachedImage
        }

        glyphImage = glyph(forBounds: imageBounds)

        return glyphImage
    }

    fileprivate func glyph(forBounds bounds: CGRect) -> UIImage? {

        let size = bounds.size

        UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0)

        let colorMessage = NSMutableAttributedString(attributedString: label)
        colorMessage.addAttribute(NSForegroundColorAttributeName, value: color, range: label.rangeOfEntireString)
        let textRect = colorMessage.boundingRect(with: size, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
        let textPosition = CGPoint(x: ((size.width - textRect.width) / 2), y: ((size.height - textRect.height) / 2) )
        colorMessage.draw(in: CGRect(origin: textPosition , size: CGSize(width: size.width, height: textRect.size.height)))

        let path = UIBezierPath()

        let dashWidth: CGFloat = 8.0
        let  dashes: [ CGFloat ] = [ dashWidth, dashWidth ]
        path.setLineDash(dashes, count: dashes.count, phase: 0.0)
        path.lineWidth = 2.0
        let centerY = round(size.height / 2.0)
        path.move(to: CGPoint(x:0, y: centerY))
        path.addLine(to: CGPoint(x: ((size.width - textRect.width) / 2) - dashWidth, y: centerY))

        path.move(to: CGPoint(x:((size.width + textRect.width) / 2) + dashWidth, y: centerY))
        path.addLine(to: CGPoint(x: size.width, y: centerY))

        color.setStroke()
        path.stroke()

        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result;
    }

    override open func attachmentBounds(for textContainer: NSTextContainer?, proposedLineFragment lineFrag: CGRect, glyphPosition position: CGPoint, characterIndex charIndex: Int) -> CGRect {

        let padding = textContainer?.lineFragmentPadding ?? 0
        let width = lineFrag.width - padding * 2
        let height:CGFloat = 44.0

        return CGRect(origin: CGPoint.zero, size: CGSize(width: width, height: height))
    }
}
