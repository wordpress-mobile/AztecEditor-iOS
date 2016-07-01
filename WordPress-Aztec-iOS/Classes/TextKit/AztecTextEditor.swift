import Foundation

///
///
class AztecTextEditor : NSObject {

    var textView: UITextView
    var storage: AztecTextStorage

    init(textView: UITextView) {
        self.storage = AztecTextStorage()
        self.textView = textView
        super.init()

        textView.textStorage.addLayoutManager(textView.layoutManager)
        textView.layoutManager.delegate = self
    }

}


///
///
extension AztecTextEditor: NSLayoutManagerDelegate
{

}
