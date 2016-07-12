import Foundation
import UIKit
import Aztec


///
///
class CursorCalloutDemoController: UIViewController
{

    @IBOutlet var textView: UITextView!

    var popover: UIViewController?


    ///
    ///
    class func controller() -> CursorCalloutDemoController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        return storyboard.instantiateViewControllerWithIdentifier("CursorCalloutDemoController") as! CursorCalloutDemoController
    }


    override func viewDidLoad() {
        super.viewDidLoad()

        configureTextView()
        configureContextMenu()
    }


    func configureTextView() {
        if let filePath = NSBundle.mainBundle().URLForResource("SampleText", withExtension: "rtf"),
            let attrStr = try? NSAttributedString(fileURL: filePath, options: [:], documentAttributes: nil) {

            textView.attributedText = attrStr
        }
    }


    func configureContextMenu() {
        let menuItem = UIMenuItem(title: "Popover", action: #selector(CursorCalloutDemoController.showPopover))
        UIMenuController.sharedMenuController().menuItems = [menuItem]
    }


    func showPopover() {
        guard popover == nil else {
            return
        }

        let controller = UIViewController()
        controller.view.backgroundColor = UIColor.lightGrayColor()
        controller.preferredContentSize = CGSize(width: 100, height: 44)
        controller.modalPresentationStyle = .Popover

        if let presentationController = controller.popoverPresentationController {
            presentationController.delegate = self
            presentationController.permittedArrowDirections = .Any
            presentationController.sourceView = textView
            presentationController.sourceRect = textView.rectForCurrentSelection()
        }
        presentViewController(controller, animated: true, completion: nil)
        popover = controller
    }

}


extension CursorCalloutDemoController: UIPopoverPresentationControllerDelegate
{
    func popoverPresentationControllerDidDismissPopover(popoverPresentationController: UIPopoverPresentationController) {
        popover = nil
    }


    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return .None
    }

}
