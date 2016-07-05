import UIKit

///
///
public class AztecTextView: UITextView
{
    var aztecStorage = AztecTextStorage()


    ///
    ///
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        setupAztecStorage()
    }
    

    ///
    ///
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupAztecStorage()
    }


    ///
    ///
    private func setupAztecStorage() {
        // Preserve any starting text
        if let attrStr = layoutManager.textStorage {
            textStorage.setAttributedString(attrStr)
        }

        // Remove the UITextView's default textStorage from the layoutManager
        layoutManager.textStorage?.removeLayoutManager(layoutManager)

        // Assign our custom textStorage to the layoutManager
        textStorage.addLayoutManager(layoutManager)
    }


    public override var textStorage: NSTextStorage {
        // Return our custom textStorage object
        return aztecStorage
    }


    public override var attributedText: NSAttributedString! {
        get {
            return NSAttributedString(attributedString: textStorage)
        }

        set {
            textStorage.setAttributedString(newValue)
        }
    }


    public override var text: String! {
        get {
            return textStorage.string
        }

        set {
            attributedText = NSAttributedString(string: newValue)
        }
    }

}
