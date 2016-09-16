import Foundation
import UIKit

/// Wrangles attachment layout and exclusion paths for the specified UITextView.
///
public class AztecAttachmentManager
{
    /// Attachments to be displayed in the Editor.
    ///
    private(set) var attachments = [AztecTextAttachment]()

    /// Maps an Attachment Identifier to an AztecAttachmentView Helper.
    ///
    private var attachmentViews = [String: UIView]()

    /// The delegate who will provide the UIViews used as content represented by AztecTextAttachments 
    /// in the UITextView's NSAttributedString.
    ///
    public weak var delegate: AztecAttachmentManagerDelegate?

    /// Editor''s TextView Instance
    ///
    private(set) public var textView: UITextView

    /// TextKit's Layout Manager
    ///
    private var layoutManager: NSLayoutManager {
        return textView.layoutManager
    }

    /// Aztec Custom TextStorage
    ///
    private var textStorage: AztecTextStorage {
        return textView.textStorage as! AztecTextStorage
    }

    /// TextKit's Text Container
    ///
    private var textContainer: NSTextContainer {
        return textView.textContainer
    }


    /// Designaged initializer.
    ///
    /// - Parameter textView: The UITextView to manage attachment layout.
    ///
    public init(textView: UITextView) {
        self.textView = textView

        reloadAttachments()
    }


    /// Returns the custom view for the specified AztecTextAttachment or nil if not found.
    ///
    /// - Parameter attachment: The AztecTextAttachment
    ///
    /// - Returns: A UIView optional
    ///
    public func viewForAttachment(attachment: AztecTextAttachment) -> UIView? {
        return attachmentViews[attachment.identifier]
    }


    /// Get the AztecTextAttachment being represented by the specified view.
    ///
    /// - Parameter view: The custom view representing the attachment.
    ///
    /// - Returns: The matching AztecTextAttachment or nil
    ///
    public func attachmentForView(view: UIView) -> AztecTextAttachment? {
        for (identifier, attachmentView) in attachmentViews where attachmentView == view {
            return attachmentForIdentifier(identifier)
        }

        return nil
    }


    /// Get the AztecTextAttachment for the specified identifier.
    ///
    /// - Parameter identifier: The identifier of the attachment.
    ///
    /// - Returns: The matching AztecTextAttachment or nil
    ///
    public func attachmentForIdentifier(identifier: String) -> AztecTextAttachment? {
        for attachment in attachments where attachment.identifier == identifier {
            return attachment
        }

        return nil
    }


    /// Get the range in text storage of the AztecTextAttachment represented by 
    /// the specified view.
    ///
    /// - Parameter view: The view representing an attachment.
    ///
    /// - Returns: The NSRange of the attachment represented by the view, or nil.
    ///
    public func rangeOfAttachmentForView(view: UIView) -> NSRange? {
        guard let targetAttachment = attachmentForView(view) else {
            return nil
        }

        var rangeOfAttachment: NSRange?

        textStorage.enumerateAttachmentsOfType(AztecTextAttachment.self) { (attachment, range) in
            guard attachment == targetAttachment else {
                return
            }

            rangeOfAttachment = range
        }

        return rangeOfAttachment
    }


    /// Returns the custom view for the specified AztecTextAttachment or nil if not found.
    ///
    /// - Parameters:
    ///     - view: The view that should be displayed for the attachment
    ///     - attachment: The AztecTextAttachment
    ///
    public func assignView(view: UIView, forAttachment attachment: AztecTextAttachment) {
        if let attachmentView = attachmentViews[attachment.identifier] {
            attachmentView.removeFromSuperview()
        }

        attachmentViews[attachment.identifier] = view
        resizeViewForAttachment(attachment, toFitInContainer: textContainer)
        textView.addSubview(view)

        layoutAttachmentViews()
    }


    /// Verifies the current Text Attachments: If the collection was updated, proceeds
    /// reloading the attachments. Otherwise, simply ensures that the layout is up to date!
    ///
    public func reloadOrLayoutAttachmentsAsNeeded() {
        guard attachments != textStorage.aztecTextAttachments() else {
            layoutAttachmentViews()
            return
        }

        reloadAttachments()
    }


    /// This method loops over any AztecTextAttachments found in textStorage and asks the delegate for a
    /// custom view for the attachment.
    ///
    public func reloadAttachments() {
        resetAttachmentManager()

        textStorage.enumerateAttachmentsOfType(AztecTextAttachment.self) { (attachment, range) in
            attachment.manager = self
            self.attachments.append(attachment)

            guard let view = self.delegate?.attachmentManager(self, viewForAttachment: attachment) else {
                return
            }

            self.attachmentViews[attachment.identifier] = view
            self.resizeViewForAttachment(attachment, toFitInContainer: self.textContainer)
            self.textView.addSubview(view)
        }

        layoutAttachmentViews()
    }


    /// Resizes and updates layout for custom attachment views so they match the 
    /// current textContainer size.
    /// Should be called when the size of the UITextView's NSTextContainer changes
    /// or from `NSLayoutManagerDelegate.layoutManager(layoutManager, textContainer, didChangeGeometryFromSize oldSize)`
    ///
    public func resizeAttachments() {
        textStorage.enumerateAttachmentsOfType(AztecTextAttachment.self) { (attachment, range) in
            self.resizeViewForAttachment(attachment, toFitInContainer: self.textContainer)
        }

        layoutAttachmentViews()
    }


    /// Updates the layout of any custom attachment views.  Call this method after
    /// making changes to the alignment or size of an attachment's custom view,
    /// or after updating an attachment's `image` property.
    ///
    public func layoutAttachmentViews() {
        layoutManager.ensureLayoutForTextContainer(textContainer)

        // HACK HACK
        // Hoping that both, God and the reviewer forgive me... this fixes several scenarios in which
        // Exclusion Paths were not being properly respected.
        // Ref. http://stackoverflow.com/questions/24681960/incorrect-exclusionpaths-with-new-lines-in-a-uitextview?noredirect=1&lq=1
        //
        textView.scrollEnabled = false
        textView.scrollEnabled = true

        // Layout
        textStorage.enumerateAttachmentsOfType(AztecTextAttachment.self) { (attachment, range) in
            self.layoutAttachmentViewForAttachment(attachment, atRange: range)
        }
    }
}



/// AztecAttachmentManager Private Helpers
///
private extension AztecAttachmentManager
{
    /// Resets the attachment manager. Any custom views for AztecTextAttachments are removed from 
    /// the UITextView, their exclusion paths are removed from textStorage.
    ///
    func resetAttachmentManager() {
        for (_, attachmentView) in attachmentViews {
            attachmentView.removeFromSuperview()
        }

        attachmentViews.removeAll()
        attachments.removeAll()
    }


    /// Updates the layout of the attachment view for the specified attachment but
    /// creating a new exclusion path for the view based on the location of the
    /// specified attachment.
    ///
    /// - Parameters:
    ///     - attachment: The AztecTextAttachment
    ///     - range: The range of the AztecTextAttachment in the textView's NSTextStorage
    ///
    private func layoutAttachmentViewForAttachment(attachment: AztecTextAttachment, atRange range: NSRange) {
        guard let view = attachmentViews[attachment.identifier] else {
            return
        }

        let size = view.frame.size
        var frame = textView.frameForTextInRange(range)

        switch attachment.alignment {
        case .Left:
            frame.origin.x = textContainer.lineFragmentPadding
        case .Center:
            frame.origin.x = round((textContainer.size.width - size.width) * 0.5)
        case .Right:
            frame.origin.x = textContainer.size.width - size.width - textContainer.lineFragmentPadding
        case .None:
            break
        }

        frame.size = size
        view.frame = frame
    }


    /// Resize (if necessary) the custom view for the specified attachment so that it fits within the
    /// width of its textContainer.
    ///
    /// Note: We also set the Attachment's Line Height!!
    ///
    /// - Parameters:
    ///     - attachment: The AztecTextAttachment
    ///     - size: Should be the size of the textContainer
    ///
    func resizeViewForAttachment(attachment: AztecTextAttachment, toFitInContainer container: NSTextContainer) {
        guard let view = attachmentViews[attachment.identifier] where view.frame.height != 0 else {
            return
        }

        guard textView.window != nil else {
            return
        }

        let visibleWidth = textContainer.size.width - (2 * textContainer.lineFragmentPadding)
        let maximumWidth = min(attachment.size.targetWidth, visibleWidth)
        let ratio = view.frame.size.width / view.frame.size.height
        let newSize = CGSize(width: floor(maximumWidth), height: floor(maximumWidth / ratio))

        view.frame.size = newSize
    }
}


/// A AztecAttachmentManagerDelegate provides custom views for AztecTextAttachments to
/// its AztecAttachmentManager.
///
public protocol AztecAttachmentManagerDelegate : NSObjectProtocol
{
    /// Delegates must implement this method and return either a UIView or nil for
    /// the specified AztecTextAttachment.
    ///
    /// - Parameters:
    ///     - attachmentManager: The AztecAttachmentManager.
    ///     - attachment: The AztecTextAttachment
    ///
    /// - Returns: A UIView to represent the specified AztecTextAttachment or nil.
    ///
    func attachmentManager(attachmentManager: AztecAttachmentManager, viewForAttachment attachment: AztecTextAttachment) -> UIView?
}
