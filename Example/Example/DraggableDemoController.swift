import Foundation
import UIKit
import Aztec


///
///
class DraggableDemoController: UIViewController
{

    @IBOutlet var textView: UITextView!
    @IBOutlet var markerView: UIView!

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

        attachmentManager = AztecAttachmentManager(textView: textView)
        attachmentManager.delegate = self

        hideMarkerView()
    }


    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        textView.attributedText = buildAttributedString()
        attachmentManager.reloadAttachments()
    }


    func buildAttributedString() -> NSAttributedString {
        let lipsum = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.\n\n"
        let attachment1 = TextAttachment(identifier: "foo")
        let attachment2 = TextAttachment(identifier: "bar")

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

        return NSAttributedString(attributedString: attrStr)
    }


    func handleLongPressGesture(gesture: UILongPressGestureRecognizer) {
        if gesture.state == .Began {
            moveMarkerView( gesture.locationInView(view) )
            showMarkerView()
        }

        if gesture.state == .Changed {
            moveMarkerView( gesture.locationInView(view) )
        }

        if gesture.state == .Ended {
            let targetView = gesture.view!
            let point = gesture.locationInView(targetView)
            if targetView.bounds.contains(point) {
                hideMarkerView()
            } else {
                showPrompt(gesture.locationInView(textView), targetView: targetView)
            }
        }
    }


    func showMarkerView() {
        markerView.hidden = false
    }


    func moveMarkerView(point: CGPoint) {
        var frame = markerView.frame
        frame.origin.x = point.x
        frame.origin.y = point.y
        markerView.frame = frame
    }


    func hideMarkerView() {
        markerView.hidden = true
    }


    func showPrompt(point: CGPoint, targetView: UIView) {
        let controller = UIAlertController(title: "Here?", message: nil, preferredStyle: .Alert)
        controller.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { (action) in
            self.hideMarkerView()
        }))
        controller.addAction(UIAlertAction(title: "OK", style: .Default, handler: { (action) in
            self.hideMarkerView()
            self.moveAttachment(point, targetView: targetView)
        }))
        presentViewController(controller, animated: true, completion: nil)
    }


    func moveAttachment(point: CGPoint, targetView: UIView) {
        // UITextRange
        let textRange = textView.characterRangeAtPoint(point)!
        var location = textView.offsetFromPosition(textView.beginningOfDocument, toPosition: textRange.start)

        // NSRange
        let attachmentRange = attachmentManager.rangeOfAttachmentForView(targetView)!
        let attachmentAttrStr = textView.textStorage.attributedSubstringFromRange(attachmentRange)

        if location > attachmentRange.location {
            location -= attachmentRange.length
        }

        // Remove the attachment
        textView.textStorage.replaceCharactersInRange(attachmentRange, withString: "")
        // Insert the attachment
        textView.textStorage.insertAttributedString(attachmentAttrStr, atIndex: location)
        attachmentManager.reloadAttachments()
    }

}


extension DraggableDemoController : UITextViewDelegate
{
    func textViewDidChange(textView: UITextView) {
        attachmentManager.reloadAttachments()
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

    func attachmentManager(attachmentManager: AztecAttachmentManager, viewForAttachment attachment: TextAttachment) -> UIView? {
        if let attachmentView = attachmentViewList[attachment.identifier] {
            return attachmentView
        }

        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 300, height: 50))
        label.text = "Example Attachment View"
        label.textAlignment = .Center
        label.backgroundColor = UIColor.lightGrayColor()
        label.font = UIFont.systemFontOfSize(20)
        label.userInteractionEnabled = true

        let lpgr = UILongPressGestureRecognizer(target: self, action: #selector(DraggableDemoController.handleLongPressGesture))
        label.addGestureRecognizer(lpgr)

        attachmentViewList[attachment.identifier] = label

        return label
    }

}
