import Foundation

/// Wrangles attachment layout and exclusion paths for the specified UITextView.
///
public class AztecAttachmentManager
{
    /// Attachments to be displayed in the Editor.
    ///
    public var attachments = [AztecTextAttachment]()

    /// Maps an Attachment Identifier to an AztecAttachmentView Helper.
    ///
    private(set) var attachmentViews = [String : AztecAttachmentView]()

    /// The delegate who will provide the UIViews used as content represented by AztecTextAttachments in the UITextView's NSAttributedString.
    ///
    public weak var delegate: AztecAttachmentManagerDelegate?

    /// Editor''s TextView Instance
    ///
    private(set) public var textView: UITextView

    /// Helper Computed Property!
    ///
    var layoutManager: NSLayoutManager {
        return textView.layoutManager
    }


    /// Designaged initializer.
    ///
    /// - Parameters:
    ///     - textView: The UITextView to manage attachment layout.
    ///
    public init(textView: UITextView) {
        self.textView = textView

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

        if let attachmentView = attachmentView {
            attachmentView.view.removeFromSuperview()
            attachmentView.view = view

        } else {
            attachmentView = AztecAttachmentView(view: view, identifier: attachment.identifier, exclusionPath: nil)
            attachmentViews[attachment.identifier] = attachmentView!
        }

        textView.addSubview(view)

        resizeViewForAttachment(attachment, toFitInContainer: textView.textContainer)

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
        let range = NSMakeRange(0, textStorage.length)
        textStorage.enumerateAttribute(NSAttachmentAttributeName, inRange: range, options: []) { (object, range, stop) in
            guard let attachment = object as? AztecTextAttachment else {
                return
            }

            self.layoutAttachmentViewForAttachment(attachment, atRange: range)
        }
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

        // Exclusion Frame needs to account for Insets, as well as line paddings!
        let newFrame = frameForAttachmentView(attachmentView, forAttachment: attachment, atRange: range)
        let newExclusionPath = exclusionPathForAttachmentFrame(newFrame, textWrapping: attachment.textWrapping)

        attachmentView.view.frame = newFrame
        attachmentView.exclusionPath = newExclusionPath

        // TextKit's Container!
        textView.textContainer.exclusionPaths.append(newExclusionPath)

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
        guard let textContainer = layoutManager.textContainerForGlyphAtIndex(glyphRange.location, effectiveRange: nil) else {
            return CGRectZero
        }

        // The location of the attachment glyph
        let lineFragmentRect = layoutManager.boundingRectForGlyphRange(glyphRange, inTextContainer: textContainer)
        let containerInset = textView.textContainerInset

        var frame = attachmentView.view.frame
        frame.origin.y = containerInset.top + lineFragmentRect.maxY
        frame.origin.x = (textView.textContainer.size.width - attachmentView.view.frame.width) * 0.5 + containerInset.left

        return frame
    }


    /// Calculates the Exclusion Path, for a given Attachment Frame, in the specified Wrapping Mode.
    ///
    /// - Parameters:
    ///     - attachmentFrame: The frame in which the attachment will be rendered.
    ///     - textWrapping: The way in which the surrounding text will be handled.
    ///
    /// - Returns: The BezierPath for the specified Attachment settings.
    ///
    private func exclusionPathForAttachmentFrame(attachmentFrame: CGRect, textWrapping: AztecTextAttachment.TextWrapping) -> UIBezierPath {
        let textInsets = textView.textContainerInset
        var newExclusion = attachmentFrame

        newExclusion.origin.x -= textInsets.left
        newExclusion.origin.y -= textInsets.top

        return UIBezierPath(rect: newExclusion)
    }


    /// Resize (if necessary) the custom view for the specified attachment so that
    /// it fits within the width of its textContainer.
    ///
    /// - Parameters:
    ///     - attachment: The AztecTextAttachment
    ///     - size: Should be the size of the textContainer
    ///
    private func resizeViewForAttachment(attachment: AztecTextAttachment, toFitInContainer container: NSTextContainer) {
        guard let attachmentView = attachmentViews[attachment.identifier] else {
            return
        }

        let view = attachmentView.view
        guard view.frame.height != 0 else {
            return
        }

        let maximumWidth = container.size.width - (2 * container.lineFragmentPadding)
        let ratio = view.frame.size.width / view.frame.size.height

        view.frame.size.width = floor(maximumWidth)
        view.frame.size.height = floor(maximumWidth / ratio)
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

        let range = NSMakeRange(0, textStorage.length)
        textStorage.enumerateAttribute(NSAttachmentAttributeName, inRange: range, options: []) { (object, range, stop) in
            guard let attachment = object as? AztecTextAttachment else {
                return
            }

            self.attachments.append(attachment)

            guard let view = self.delegate?.attachmentManager(self, viewForAttachment: attachment) else {
                return
            }

            self.attachmentViews[attachment.identifier] = AztecAttachmentView(view: view, identifier: attachment.identifier, exclusionPath: nil)
            self.resizeViewForAttachment(attachment, toFitInContainer: self.textView.textContainer)
            self.textView.addSubview(view)
        }

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

        let textContainer = textView.textContainer
        let range = NSMakeRange(0, textStorage.length)

        textStorage.enumerateAttribute(NSAttachmentAttributeName, inRange: range, options: []) { (object, range, stop) in
            guard let attachment = object as? AztecTextAttachment else {
                return
            }

            self.resizeViewForAttachment(attachment, toFitInContainer: textContainer)
        }

        layoutAttachmentViews()
    }


    /// Resets the attachment manager. Any custom views for AztecTextAttachments are
    /// removed from the UITextView, their exclusion paths are removed from 
    /// textStorage.
    ///
    private func resetAttachmentManager() {
        // Clean up any stale exclusion paths
        removeAttachmentExclusionPaths()

        for (identifier, attachmentView) in attachmentViews {
            attachmentView.view.removeFromSuperview()
        }

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
    /// Identifier used to match this helper with an AztecTextAttachment Instance.
    ///
    let identifier: String

    /// View to be rendered onscreen.
    ///
    var view: UIView

    /// Path that should be sent over to the TextStorage, for exclusion purposes.
    ///
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
    public var textWrapping = TextWrapping.Around


    /// Designed Initializer
    ///
    public init(identifier: String) {
        self.identifier = identifier
        super.init(data: nil, ofType: nil)
    }

    required public init?(coder aDecoder: NSCoder) {
        self.identifier = ""
        super.init(coder: aDecoder)
    }
}
