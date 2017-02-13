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
        return storyboard.instantiateViewController(withIdentifier: "CursorCalloutDemoController") as! CursorCalloutDemoController
    }


    override func viewDidLoad() {
        super.viewDidLoad()

        configureTextView()
        configureContextMenu()
    }


    func configureTextView() {
        if let filePath = Bundle.main.url(forResource: "SampleText", withExtension: "rtf"),
            let attrStr = try? NSAttributedString(url: filePath, options: [:], documentAttributes: nil) {

            textView.attributedText = attrStr
        }
    }


    func configureContextMenu() {
        let menuItem = UIMenuItem(title: "Popover", action: #selector(CursorCalloutDemoController.showPopover))
        UIMenuController.shared.menuItems = [menuItem]
    }


    func showPopover() {
        guard popover == nil else {
            return
        }

        let controller = UIViewController()
        controller.view.backgroundColor = UIColor.lightGray
        controller.preferredContentSize = CGSize(width: 100, height: 44)
        controller.modalPresentationStyle = .popover

        if let presentationController = controller.popoverPresentationController {
            presentationController.delegate = self
            presentationController.permittedArrowDirections = .any
            presentationController.sourceView = textView
            presentationController.sourceRect = textView.rectForCurrentSelection()
        }
        present(controller, animated: true, completion: nil)
        popover = controller
    }

}


extension CursorCalloutDemoController: UIPopoverPresentationControllerDelegate
{
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        popover = nil
    }


    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }

}
