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

        configureEditor()
    }


    func configureEditor() {
        editor = AztecTextEditor(textView: textView)
        if let filePath = NSBundle.mainBundle().URLForResource("SampleText", withExtension: "rtf"),
            let attrStr = try? NSAttributedString(fileURL: filePath, options: [:], documentAttributes: nil) {

//            editor.storage.appendAttributedString(attrStr)
            textView.attributedText = attrStr
        }
    }



    

}
