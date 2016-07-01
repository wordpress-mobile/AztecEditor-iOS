import Foundation


///
///
public class AztecTextEditor : NSObject {

    var textView: UITextView
    public private(set) var storage: AztecTextStorage

    public init(textView: UITextView) {
        self.storage = AztecTextStorage()
        self.textView = textView
        super.init()

        storage.addLayoutManager(textView.layoutManager)
        textView.layoutManager.delegate = self
    }

}


///
///
extension AztecTextEditor: NSLayoutManagerDelegate
{

}
