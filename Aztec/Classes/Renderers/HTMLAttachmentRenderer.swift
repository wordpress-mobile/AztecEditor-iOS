import Foundation
import UIKit


// MARK: - HTMLAttachmentRenderer: Renders Unknown HTML
//
final public class HTMLAttachmentRenderer {

    /// Comment Attachment Text
    ///
    let defaultText = NSLocalizedString("HTML", comment: "HTML Attachment Label")

    /// Text Color
    ///
    var textColor = UIColor.gray

    /// Text Font
    ///
    var textFont: UIFont


    /// Default Initializer
    ///
    public init(font: UIFont) {
        self.textFont = font
    }
}


// MARK: - TextViewCommentsDelegate Methods
//
extension HTMLAttachmentRenderer: TextViewAttachmentImageProvider {

    public func textView(_ textView: TextView, shouldRender attachment: NSTextAttachment) -> Bool {
        return attachment is HTMLAttachment
    }

    public func textView(_ textView: TextView, imageFor attachment: NSTextAttachment, with size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)

        guard let attachment = attachment as? HTMLAttachment else {
            return nil
        }
        
        let message = messageAttributedString(with: attachment)
        let targetRect = boundingRect(for: message, size: size)

        message.draw(in: targetRect)

        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return result
    }

    public func textView(_ textView: TextView, boundsFor attachment: NSTextAttachment, with lineFragment: CGRect) -> CGRect {
        guard let attachment = attachment as? HTMLAttachment else {
            return .zero
        }
        
        let message = messageAttributedString(with: attachment)

        let size = CGSize(width: lineFragment.size.width, height: lineFragment.size.height)
        var rect = boundingRect(for: message, size: size)
        rect.origin.y = textFont.descender

        return rect.integral
    }
}


// MARK: - Private Methods
//
private extension HTMLAttachmentRenderer {

    private func boundingRect(for message: NSAttributedString, size: CGSize) -> CGRect {
        let targetBounds = message.boundingRect(with: size, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
        let targetPosition = CGPoint(x: ((size.width - targetBounds.width) * 0.5), y: ((size.height - targetBounds.height) * 0.5))

        return CGRect(origin: targetPosition, size: targetBounds.size)
    }

    private func messageAttributedString(with attachment: HTMLAttachment) -> NSAttributedString {
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: textColor,
            .font: textFont
        ]

        let displayText = attachment.rootTagName.count > 0 ? attachment.rootTagName.uppercased() : defaultText

        return NSAttributedString(string: "[\(displayText)]", attributes: attributes)
    }
}
