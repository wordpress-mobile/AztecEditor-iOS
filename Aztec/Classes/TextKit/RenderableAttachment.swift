import Foundation
import UIKit


/// NSTextAttachment Renderable Delegate Helpers
///
public protocol RenderableAttachmentDelegate: class {

    /// Returns the Bounds that should be used to render a given attachment
    ///
    /// - Parameters:
    ///     - attachment: Attachment to be rendered
    ///     - fragment: Current Line Fragment Bounds
    ///
    /// - Returns: CGRect specifiying the Attachment Bounds.
    ///
    func attachment(_ attachment: NSTextAttachment, boundsForLineFragment fragment: CGRect) -> CGRect

    /// Returns the Image Representation for a given attachment.
    ///
    /// - Parameters:
    ///     - attachment: Attachment to be rendered
    ///     - size: The Canvas Size
    ///
    /// - Returns: Optional UIImage instance, representing a given comment.
    ///
    func attachment(_ attachment: NSTextAttachment, imageForSize size: CGSize) -> UIImage?
}

/// Protocol to mark attachments object that are renderable through the delegate interface.
///
public protocol RenderableAttachment: class {

    var delegate: RenderableAttachmentDelegate? {get set}
}
