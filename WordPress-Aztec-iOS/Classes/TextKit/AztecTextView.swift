import UIKit

/// A UITextView internally configured to use an AztecTextStorage instance in its
/// TextKit stack.
///
public class AztecTextView: UITextView
{
    // Replaces the default NSTextStorage instance.
    let aztecStorage = AztecTextStorage()


    /// Overrides the designated initializer to setup our custom AztecTextStorage 
    /// instance.
    ///
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        setupAztecStorage()
    }
    

    /// Overrides `initWithCoder`: to setup our custom AztecTextStorage
    /// instance.
    ///
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupAztecStorage()
    }


    /// Configures the internal NSTextStorage and NSLayoutManger to use an instance
    /// of AztecTextStorage instead of the default NSTextStorage instance.
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


    /// Overrides to returns our custom textStorage instance. The default implementation
    /// always returns the NSTextStorage instance assigned during initializaion,
    /// even if the `textContainer`'s `layoutManager` is replaced.
    ///
    public override var textStorage: NSTextStorage {
        return aztecStorage
    }


    /// Override to interact with our custom textStorage instead of the internal 
    /// textStorage instance created during initialization.
    public override var attributedText: NSAttributedString! {
        get {
            return NSAttributedString(attributedString: textStorage)
        }

        set {
            textStorage.setAttributedString(newValue)
        }
    }


    /// Override to interact with our custom textStorage instead of the internal
    /// textStorage instance created during initialization.
    public override var text: String! {
        get {
            return textStorage.string
        }

        set {
            attributedText = NSAttributedString(string: newValue)
        }
    }

}
