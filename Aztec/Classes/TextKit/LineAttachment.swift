import Foundation
import UIKit


/// Custom horizontal line drawing attachment.
///
open class LineAttachment: NSTextAttachment {

    fileprivate var glyphImage: UIImage?

    /// The color to use when drawing progress indicators
    ///
    open var color = UIColor.gray

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

        color.setStroke()
        let path = UIBezierPath()
        path.lineWidth = 1.0
        path.move(to: CGPoint(x:0, y:bounds.height / 2))
        path.addLine(to: CGPoint(x: size.width, y: bounds.height / 2))
        path.stroke()

        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result;
    }

    override open func attachmentBounds(for textContainer: NSTextContainer?, proposedLineFragment lineFrag: CGRect, glyphPosition position: CGPoint, characterIndex charIndex: Int) -> CGRect {

        let padding = textContainer?.lineFragmentPadding ?? 0
        let width = lineFrag.width - padding * 2
        let height:CGFloat = 22.0

        return CGRect(origin: CGPoint.zero, size: CGSize(width: width, height: height))
    }
}
