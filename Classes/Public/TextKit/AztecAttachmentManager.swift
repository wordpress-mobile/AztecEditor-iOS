import Foundation

/// Wrangles attachment layout and exclusion paths for the specified UITextView.
///
public class AztecAttachmentManager
{

    public var attachments = [AztecTextAttachment]()
    var attachmentViews = [String : AztecAttachmentView]()
    public weak var delegate: AztecAttachmentManagerDelegate?
    private(set) public var textView:UITextView

    var layoutManager: NSLayoutManager {
        return textView.layoutManager
    }


    /// Designaged initializer.
    ///
    /// - Parameters:
    ///     - textView: The UITextView to manage attachment layout.
    ///     - delegate: The delegate who will provide the UIViews used as content represented by AztecTextAttachments in the UITextView's NSAttributedString.
    ///
    public init(textView: UITextView, delegate: AztecAttachmentManagerDelegate) {
        self.textView = textView
        self.delegate = delegate

        enumerateAttachments()
    }


    /// Returns the custom view for the specified AztecTextAttachment or nil if not found.
    ///
    /// - Parameters:
    ///     - attachment: The AztecTextAttachment
    ///
    /// - Returns: A UIView optional
    ///
    public func viewForAttachment(attachment: AztecTextAttachment) -> UIView? {
        return attachmentViews[attachment.identifier]?.view
    }


    /// Get the AztecTextAttachment being represented by the specified view.
    ///
    /// - Parameters:
    ///     - view: The custom view representing the attachment.
    ///
    /// - Returns: The matching AztecTextAttachment or nil
    ///
    public func attachmentForView(view: UIView) -> AztecTextAttachment? {
        for (identifier, attachmentView)  in attachmentViews {
            if attachmentView.view == view {
                return attachmentForIdentifier(identifier)
            }
        }
        return nil
    }


    /// Get the AztecTextAttachment for the specified identifier.
    ///
    /// - Parameters:
    ///     - identifier: The identifier of the attachment.
    ///
    /// - Returns: The matching AztecTextAttachment or nil
    ///
    public func attachmentForIdentifier(identifier: String) -> AztecTextAttachment? {
        for attachment in attachments {
            if attachment.identifier == identifier {
                return attachment
            }
        }
        return nil
    }


    /// Get the range in text storage of the AztecTextAttachment represented by 
    /// the specified view.
    ///
    /// - Paramters:
    ///     - view: The view representing an attachment.
    ///
    /// - Returns: The NSRange of the attachment represented by the view, or nil.
    ///
    public func rangeOfAttachmentForView(view: UIView) -> NSRange? {
        var rangeOfAttachment: NSRange?

        guard let targetAttachment = attachmentForView(view),
            textStorage = layoutManager.textStorage else
        {
            return rangeOfAttachment
        }

        textStorage.enumerateAttribute(NSAttachmentAttributeName,
                                       inRange: NSMakeRange(0, textStorage.length),
                                       options: [],
                                       usingBlock: { (object: AnyObject?, range: NSRange, stop: UnsafeMutablePointer<ObjCBool>) in
                                        guard let attachment = object as? AztecTextAttachment else {
                                            return
                                        }
                                        if attachment == targetAttachment {
                                            rangeOfAttachment = range
                                        }

        })
        return rangeOfAttachment
    }


    /// Returns the custom view for the specified AztecTextAttachment or nil if not found.
    ///
    /// - Parameters:
    ///     - view: The view that should be displayed for the attachment
    ///     - attachment: The AztecTextAttachment
    ///
    public func assignView(view: UIView, forAttachment attachment: AztecTextAttachment) {
        var attachmentView = attachmentViews[attachment.identifier]

        if attachmentView != nil {
            attachmentView!.view.removeFromSuperview()
            attachmentView!.view = view

        } else {
            attachmentView = AztecAttachmentView(view: view, identifier: attachment.identifier, exclusionPath: nil)
            attachmentViews[attachment.identifier] = attachmentView!
        }

        textView.addSubview(view)

        resizeViewForAttachment(attachment, toFitSize: textView.textContainer.size)

        layoutAttachmentViews()
    }


    /// Updates the layout of any custom attachment views.  Call this method after
    /// making changes to the alignment or size of an attachment's custom view,
    /// or after updating an attachment's `image` property.
    ///
    public func layoutAttachmentViews() {
        // Guard for paranoia
        guard let textStorage = layoutManager.textStorage else {
            assertionFailure("Unable to layout attachment views. No NSTextStorage.")
            return
        }

        // Remove any existing attachment exclusion paths and ensure layout.
        // This ensures previous (soon to be invalid) exclusion paths do not
        // conflict with the new layout.
        removeAttachmentExclusionPaths()

        layoutManager.ensureLayoutForTextContainer(textView.textContainer)

        // Now do the update.
        textStorage.enumerateAttribute(NSAttachmentAttributeName,
                                       inRange: NSMakeRange(0, textStorage.length),
                                       options: [],
                                       usingBlock: { (object: AnyObject?, range: NSRange, stop: UnsafeMutablePointer<ObjCBool>) in
                                        guard let attachment = object as? AztecTextAttachment else {
                                            return
                                        }
                                        self.layoutAttachmentViewForAttachment(attachment, atRange: range)
        })
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
        guard let attachmentView = attachmentViews[attachment.identifier] else {
            return
        }

        var exclusionPaths = textView.textContainer.exclusionPaths

        var exclusionFrame = frameForAttachmentView(attachmentView, forAttachment: attachment, atRange: range)
        exclusionFrame.origin.y -= textView.textContainerInset.top

        let newExclusionPath = UIBezierPath(rect: exclusionFrame)
        exclusionPaths.append(newExclusionPath)

        attachmentView.exclusionPath = newExclusionPath
        attachmentView.view.frame = exclusionFrame

        textView.textContainer.exclusionPaths = exclusionPaths

        // Always ensure layout after updating an individual exclusion path so
        // subsequent attachments are in their proper location.
        layoutManager.ensureLayoutForTextContainer(textView.textContainer)
    }


    /// Computes the frame for an attachment's custom view based on alignment
    /// and the size of the attachment.  Attachments with a maxSize of CGSizeZero
    /// will scale to match the current width of the textContainer. Attachments
    /// with a maxSize greater than CGSizeZero will never scale up, but may be
    /// scaled down to match the width of the textContainer.
    ///
    /// - Parameters:
    ///     - attachmentView: The AztecAttachmentView in question.
    ///     - attachment: The AztecTextAttachment
    ///     - range: The range of the AztecTextAttachment in the textView's NSTextStorage
    ///
    /// - Returns: The frame for the specified custom attachment view.
    ///
    private func frameForAttachmentView(attachmentView: AztecAttachmentView, forAttachment attachment: AztecTextAttachment, atRange range:NSRange) -> CGRect {
        let glyphRange = layoutManager.glyphRangeForCharacterRange(range, actualCharacterRange: nil)
        guard let _ = layoutManager.textContainerForGlyphAtIndex(glyphRange.location, effectiveRange: nil) else {
            return CGRectZero
        }

        // The location of the attachment glyph
        let lineFragmentRect = layoutManager.lineFragmentRectForGlyphAtIndex(glyphRange.location, effectiveRange: nil)

        // Place on the same line if the attachment glyph is at the beginning of the line fragment, otherwise the next line.

        var frame = attachmentView.view.frame
        // TODO: The padding should probably be (lineheight - capheight) / 2.
        let topLinePadding:CGFloat = 4.0

        frame.origin.y = lineFragmentRect.minY + textView.textContainerInset.top + topLinePadding;
        frame.origin.x = textView.textContainer.size.width / 2.0 - (attachmentView.view.frame.width / 2.0)

        return frame
    }


    /// Resize (if necessary) the custom view for the specified attachment so that
    /// it fits within the width of its textContainer.
    ///
    /// - Parameters:
    ///     - attachment: The AztecTextAttachment
    ///     - size: Should be the size of the textContainer
    ///
    private func resizeViewForAttachment(attachment: AztecTextAttachment, toFitSize size: CGSize) {
        guard let attachmentView = attachmentViews[attachment.identifier] else {
            return
        }

        let view = attachmentView.view
        if view.frame.height == 0 {
            return
        }

        let ratio = view.frame.size.width / view.frame.size.height

        view.frame.size.width = floor(size.width)
        view.frame.size.height = floor(size.width / ratio)
    }


    /// After resetting the attachment manager, this method loops over any
    /// AztecTextAttachments found in textStorage and asks the delegate for a
    /// custom view for the attachment.
    ///
    private func enumerateAttachments() {
        resetAttachmentManager()

        guard let textStorage = layoutManager.textStorage else {
            assertionFailure("Unable to enumerate attachments. No NSTextStorage.")
            return
        }

        textStorage.enumerateAttribute(NSAttachmentAttributeName,
                                       inRange: NSMakeRange(0, textStorage.length),
                                       options: [],
                                       usingBlock: { (object:AnyObject?, range:NSRange, stop:UnsafeMutablePointer<ObjCBool>) in
                                        guard let attachment = object as? AztecTextAttachment else {
                                            return
                                        }
                                        self.attachments.append(attachment)

                                        if let view = self.delegate?.attachmentManager(self, viewForAttachment: attachment) {
                                            self.attachmentViews[attachment.identifier] = AztecAttachmentView(view: view, identifier: attachment.identifier, exclusionPath: nil)
                                            self.resizeViewForAttachment(attachment, toFitSize: self.textView.textContainer.size)
                                            self.textView.addSubview(view)
                                        }
        })

        layoutAttachmentViews()
    }


    /// Updates the layout and position of attachment views.  Should be called
    /// whenever the text in the textView changes.
    ///
    public func updateAttachmentLayout() {
        enumerateAttachments()
    }


    /// Resizes and updates layout for custom attachment views so they match the 
    /// current textContainer size.
    /// Should be called when the size of the UITextView's NSTextContainer changes
    /// or from `NSLayoutManagerDelegate.layoutManager(layoutManager, textContainer, didChangeGeometryFromSize oldSize)`
    ///
    public func resizeAttachments() {
        guard let textStorage = layoutManager.textStorage else {
            return
        }

        let newSize = textView.textContainer.size
        textStorage.enumerateAttribute(NSAttachmentAttributeName,
                                       inRange: NSMakeRange(0, textStorage.length),
                                       options: [],
                                       usingBlock: { (object: AnyObject?, range: NSRange, stop: UnsafeMutablePointer<ObjCBool>) in
                                        guard let attachment = object as? AztecTextAttachment else {
                                            return
                                        }

                                        self.resizeViewForAttachment(attachment, toFitSize: newSize)
        })

        layoutAttachmentViews()
    }


    /// Resets the attachment manager. Any custom views for AztecTextAttachments are
    /// removed from the UITextView, their exclusion paths are removed from 
    /// textStorage.
    ///
    private func resetAttachmentManager() {
        // Clean up any stale exclusion paths
        removeAttachmentExclusionPaths()

        attachmentViews.removeAll()
        attachments.removeAll()
    }


    ///
    ///
    private func removeAttachmentExclusionPaths() {
        let textContainer = textView.textContainer

        let paths = attachmentViews.flatMap { (identifier, attachmentView) -> UIBezierPath? in
            return attachmentView.exclusionPath
        }
        let pathsToKeep = textContainer.exclusionPaths.filter { (bezierPath) -> Bool in
            return !paths.contains(bezierPath)
        }

        textContainer.exclusionPaths = pathsToKeep
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


/// A convenience class for grouping a custom view with its attachment and
/// exclusion path.
///
class AztecAttachmentView
{
    var view: UIView
    var identifier: String
    var exclusionPath: UIBezierPath?
    init(view: UIView, identifier: String, exclusionPath: UIBezierPath?) {
        self.view = view
        self.identifier = identifier
        self.exclusionPath = exclusionPath
    }
}


/// Custom text attachment.
///
public class AztecTextAttachment: NSTextAttachment
{
    private(set) public var identifier: String


    public init(identifier: String) {
        self.identifier = identifier
        super.init(data: nil, ofType: nil)
    }


    required public init?(coder aDecoder: NSCoder) {
        self.identifier = ""
        super.init(coder: aDecoder)
    }
}
