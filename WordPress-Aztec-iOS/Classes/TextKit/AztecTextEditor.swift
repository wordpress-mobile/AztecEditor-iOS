import Foundation


public class AztecTextEditor : NSObject {

    let textView: UITextView
    var attachmentManager: AztecAttachmentManager!

    /// Returns a UITextView whose TextKit stack is composted to use AztecTextStorage.
    ///
    /// - Returns: A UITextView.
    ///
    public class func createTextView() -> UITextView {
        let storage = AztecTextStorage()
        let layoutManager = NSLayoutManager()
        let container = NSTextContainer()

        storage.addLayoutManager(layoutManager)
        layoutManager.addTextContainer(container)
        container.widthTracksTextView = true

        return UITextView(frame: CGRectMake(0, 0, 100, 44), textContainer: container)
    }


    public init(textView: UITextView) {
        self.textView = textView

        super.init()

        attachmentManager = AztecAttachmentManager(textView: textView, delegate: self)
        textView.layoutManager.delegate = self
    }

}


/// Stubs an NSLayoutManagerDelegate
///
extension AztecTextEditor: NSLayoutManagerDelegate
{

}


/// Stubs an AztecAttachmentManagerDelegate
///
extension AztecTextEditor: AztecAttachmentManagerDelegate
{
    public func attachmentManager(attachmentManager: AztecAttachmentManager, viewForAttachment attachment: AztecTextAttachment) -> UIView? {
        return nil
    }
}
