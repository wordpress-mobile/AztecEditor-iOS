import Foundation
import UIKit
import Aztec


///
///
class DraggableDemoController: UIViewController
{

    @IBOutlet var textView: UITextView!

    var editor: AztecTextEditor!

    
    ///
    ///
    class func controller() -> DraggableDemoController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        return storyboard.instantiateViewControllerWithIdentifier("DraggableDemoController") as! DraggableDemoController
    }


    override func viewDidLoad() {
        super.viewDidLoad()

        editor = AztecTextEditor(textView: textView)
    }

}
