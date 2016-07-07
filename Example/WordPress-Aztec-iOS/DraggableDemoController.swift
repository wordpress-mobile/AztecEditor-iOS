import Foundation
import UIKit
import Aztec


///
///
class DraggableDemoController: UIViewController
{

    @IBOutlet var textView: UITextView!

    var attachmentManager: AztecAttachmentManager!
    var attachmentViewList = [String: UIView]()


    ///
    ///
    class func controller() -> DraggableDemoController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        return storyboard.instantiateViewControllerWithIdentifier("DraggableDemoController") as! DraggableDemoController
    }


    override func viewDidLoad() {
        super.viewDidLoad()

        textView.layoutManager.delegate = self
        textView.delegate = self
        textView.attributedText = buildAttributedString()
        attachmentManager = AztecAttachmentManager(textView: textView, delegate: self)

    }



    func buildAttributedString() -> NSAttributedString {
        let lipsum = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.\n\n"
        let attachment1 = AztecTextAttachment(identifier: "foo")
        let attachment2 = AztecTextAttachment(identifier: "bar")

        let attributes = [
            NSParagraphStyleAttributeName : NSParagraphStyle.defaultParagraphStyle(),
            NSFontAttributeName: UIFont.systemFontOfSize(16)
        ]

        let attrStr = NSMutableAttributedString()
        attrStr.appendAttributedString(NSAttributedString(string: lipsum, attributes: attributes))
        attrStr.appendAttributedString(NSAttributedString(attachment: attachment1))
        attrStr.appendAttributedString(NSAttributedString(string: lipsum, attributes: attributes))
        attrStr.appendAttributedString(NSAttributedString(attachment: attachment2))
        attrStr.appendAttributedString(NSAttributedString(string: lipsum, attributes: attributes))
        attrStr.appendAttributedString(NSAttributedString(string: lipsum, attributes: attributes))
        attrStr.appendAttributedString(NSAttributedString(string: lipsum, attributes: attributes))

        return NSAttributedString(attributedString: attrStr)
    }

}


extension DraggableDemoController : UITextViewDelegate
{
    func textViewDidChange(textView: UITextView) {
        attachmentManager.updateAttachmentLayout()
    }
}


extension DraggableDemoController : NSLayoutManagerDelegate
{
    func layoutManager(layoutManager: NSLayoutManager, textContainer: NSTextContainer, didChangeGeometryFromSize oldSize: CGSize) {
        attachmentManager.resizeAttachments()
    }
}


extension DraggableDemoController : AztecAttachmentManagerDelegate
{

    func attachmentManager(attachmentManager: AztecAttachmentManager, viewForAttachment attachment: AztecTextAttachment) -> UIView? {
        if let attachmentView = attachmentViewList[attachment.identifier] {
            return attachmentView
        }

        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 300, height: 50))
        label.text = "Example Attachment View"
        label.textAlignment = .Center
        label.backgroundColor = UIColor.lightGrayColor()
        label.font = UIFont.systemFontOfSize(20)

        attachmentViewList[attachment.identifier] = label

        return label
    }

}
