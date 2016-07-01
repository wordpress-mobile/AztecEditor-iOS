import Foundation


///
///
public class AztecTextStorage: NSTextStorage {

    private var textStore = NSMutableAttributedString(string: "", attributes: nil)


    override public var string: String {
        return textStore.string
    }


    override public func attributesAtIndex(location: Int, effectiveRange range: NSRangePointer) -> [String : AnyObject] {
        return textStore.attributesAtIndex(location, effectiveRange: range)
    }


    override public func replaceCharactersInRange(range: NSRange, withString str: String) {
        beginEditing()

        // NOTE: Hook in any custom attribute handling here.

        textStore.replaceCharactersInRange(range, withString:str)
        edited(.EditedCharacters, range: range, changeInLength: (str as NSString).length - range.length)

        endEditing()
    }


    override public func setAttributes(attrs: [String : AnyObject]?, range: NSRange) {
        beginEditing()

        // NOTE: Hook in any custom attribute handling here.

        textStore.setAttributes(attrs, range: range)
        edited(.EditedAttributes, range: range, changeInLength: 0)

        endEditing()
    }


    override public func processEditing() {
        // Edits have happened and are about to be implemented.
        // Do any last minute changes here *BEFORE* calling super.about

        super.processEditing()
    }
}
