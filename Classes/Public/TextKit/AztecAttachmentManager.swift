import Foundation

/// Wrangles attachment layout and exclusion paths for the specified UITextView.
///
public class AztecAttachmentManager
{
    /// Attachments to be displayed in the Editor.
    ///
    private(set) var attachments = [AztecTextAttachment]()

    /// Maps an Attachment Identifier to an AztecAttachmentView Helper.
    ///
    private var attachmentViews = [String : AztecAttachmentView]()

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
    /// - Parameters:
    ///     - textView: The UITextView to manage attachment layout.
    ///
    public init(textView: UITextView) {
        self.textView = textView

        reloadAttachments()
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
        for (identifier, attachmentView) in attachmentViews where attachmentView.view == view {
            return attachmentForIdentifier(identifier)
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
        for attachment in attachments where attachment.identifier == identifier {
            return attachment
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
        guard let targetAttachment = attachmentForView(view), textStorage = layoutManager.textStorage else {
            return nil
        }

        var rangeOfAttachment: NSRange?

        enumerateAttachments(ofType: AztecTextAttachment.self) { (attachment, range) in
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
        var attachmentView = attachmentViews[attachment.identifier]

        if let attachmentView = attachmentView {
            attachmentView.view.removeFromSuperview()
            attachmentView.view = view

        } else {
            attachmentView = AztecAttachmentView(view: view, identifier: attachment.identifier)
            attachmentViews[attachment.identifier] = attachmentView!
        }

        textView.addSubview(view)

        resizeViewForAttachment(attachment, toFitInContainer: textView.textContainer)

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

        enumerateAttachments(ofType: AztecTextAttachment.self) { (attachment, range) in
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


    /// Resizes and updates layout for custom attachment views so they match the 
    /// current textContainer size.
    /// Should be called when the size of the UITextView's NSTextContainer changes
    /// or from `NSLayoutManagerDelegate.layoutManager(layoutManager, textContainer, didChangeGeometryFromSize oldSize)`
    ///
    public func resizeAttachments() {
        let textContainer = textView.textContainer

        enumerateAttachments(ofType: AztecTextAttachment.self) { (attachment, range) in
            self.resizeViewForAttachment(attachment, toFitInContainer: textContainer)
        }

        layoutAttachmentViews()
    }


    /// Updates the layout of any custom attachment views.  Call this method after
    /// making changes to the alignment or size of an attachment's custom view,
    /// or after updating an attachment's `image` property.
    ///
    public func layoutAttachmentViews() {
        // Remove any existing attachment exclusion paths and ensure layout.
        // This ensures previous (soon to be invalid) exclusion paths do not
        // conflict with the new layout.
        removeAttachmentExclusionPaths()

        layoutManager.ensureLayoutForTextContainer(textView.textContainer)

        // Layout
        enumerateAttachments(ofType: AztecTextAttachment.self) { (attachment, range) in
            self.layoutAttachmentViewForAttachment(attachment, atRange: range)
        }

        // HACK HACK
        // Hoping that both, God and the reviewer forgive me... this fixes several scenarios in which 
        // Exclusion Paths were not being properly respected.
        // Ref. http://stackoverflow.com/questions/24681960/incorrect-exclusionpaths-with-new-lines-in-a-uitextview?noredirect=1&lq=1
        //
        textView.scrollEnabled = false
        textView.scrollEnabled = true
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
        // Clean up any stale exclusion paths
        removeAttachmentExclusionPaths()

        for (identifier, attachmentView) in attachmentViews {
            attachmentView.view.removeFromSuperview()
        }

        attachmentViews.removeAll()
        attachments.removeAll()
    }


    /// Nukes all of the ExclusionPaths associated to the AttachmentViews collection.
    ///
    func removeAttachmentExclusionPaths() {
        let textContainer = textView.textContainer

        let paths = attachmentViews.flatMap { (identifier, attachmentView) -> UIBezierPath? in
            return attachmentView.exclusionPath
        }
        let pathsToKeep = textContainer.exclusionPaths.filter { (bezierPath) -> Bool in
            return !paths.contains(bezierPath)
        }

        textContainer.exclusionPaths = pathsToKeep
    }


    /// Enumerates all of the available NSTextAttachment's of the specified kind, in a given range.
    /// For each one of those elements, the specified block will be called.
    ///
    /// - Parameters:
    ///     - range: The range that should be checked. Nil wil cause the whole text to be scanned
    ///     - type: The kind of Attachment we're after
    ///     - block: Closure to be executed, for each one of the elements
    ///
    func enumerateAttachments<T : NSTextAttachment>(range: NSRange? = nil, ofType type: T.Type, block: ((T, NSRange) -> Void)) {
        guard let textStorage = layoutManager.textStorage else {
            assertionFailure("Unable to enumerate attachments. No NSTextStorage.")
            return
        }

        let range = range ?? NSMakeRange(0, textStorage.length)
        textStorage.enumerateAttribute(NSAttachmentAttributeName, inRange: range, options: []) { (object, range, stop) in
            if let object = object as? T {
                block(object, range)
            }
        }
    }
}


/// AztecAttachmentManager Layout Helpers
///
private extension AztecAttachmentManager
{
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

        textContainer.exclusionPaths.append(newExclusionPath)
        layoutManager.ensureLayoutForTextContainer(textContainer)
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
    func frameForAttachmentView(attachmentView: AztecAttachmentView, forAttachment attachment: AztecTextAttachment, atRange range:NSRange) -> CGRect {
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
    func exclusionPathForAttachmentFrame(attachmentFrame: CGRect, textWrapping: AztecTextAttachment.TextWrapping) -> UIBezierPath {
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
    func resizeViewForAttachment(attachment: AztecTextAttachment, toFitInContainer container: NSTextContainer) {
        guard let attachmentView = attachmentViews[attachment.identifier] where attachmentView.view.frame.height != 0 else {
            return
        }

        let view = attachmentView.view
        let maximumWidth = container.size.width - (2 * container.lineFragmentPadding)
        let ratio = view.frame.size.width / view.frame.size.height

        view.frame.size.width = floor(maximumWidth)
        view.frame.size.height = floor(maximumWidth / ratio)
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


/// A convenience class for grouping a custom view with its attachment and exclusion path.
///
private class AztecAttachmentView
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


    init(view: UIView, identifier: String, exclusionPath: UIBezierPath? = nil) {
        self.view = view
        self.identifier = identifier
        self.exclusionPath = exclusionPath
    }
}
