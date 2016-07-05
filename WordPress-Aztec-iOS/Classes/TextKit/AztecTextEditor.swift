import Foundation


///
///
public class AztecTextEditor : NSObject {

    var textView: UITextView


    public init(textView: UITextView) {
        self.textView = textView
        super.init()

        textView.layoutManager.delegate = self
    }

}


///
///
extension AztecTextEditor: NSLayoutManagerDelegate
{

}
