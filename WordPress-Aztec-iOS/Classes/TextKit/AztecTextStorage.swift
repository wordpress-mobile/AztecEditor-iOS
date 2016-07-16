import Foundation


/// Custom NSTextStorage
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

public extension AztecTextStorage
{



    public func toggleFontTrait(trait: UIFontDescriptorSymbolicTraits, range: NSRange) {
        // Bail if nothing is selected
        if range.length == 0 {
            return
        }

        var assigning = false

        // Assume we're removing the trait. If the trait is missing anywhere in the range assign it.
        enumerateAttribute(NSFontAttributeName,
                                   inRange: range,
                                   options: [],
                                   usingBlock: { (object: AnyObject?, range: NSRange, stop: UnsafeMutablePointer<ObjCBool>) in
                                    guard let font = object as? UIFont else {
                                        return
                                    }
                                    if !font.fontDescriptor().symbolicTraits.contains(trait) {
                                        assigning = true
                                        stop.memory = true
                                    }
        })

        // Enumerate over each font and either assign or remove the trait.
        enumerateAttribute(NSFontAttributeName,
                                   inRange: range,
                                   options: [],
                                   usingBlock: { (object: AnyObject?, range: NSRange, stop: UnsafeMutablePointer<ObjCBool>) in
                                    guard let font = object as? UIFont else {
                                        return
                                    }

                                    var newTraits: UInt32
                                    if assigning {
                                        newTraits =  font.fontDescriptor().symbolicTraits.rawValue | trait.rawValue

                                    } else {
                                        newTraits =  font.fontDescriptor().symbolicTraits.rawValue & ~trait.rawValue
                                    }

                                    let descriptor = font.fontDescriptor().fontDescriptorWithSymbolicTraits(UIFontDescriptorSymbolicTraits(rawValue: newTraits))
                                    let newFont = UIFont(descriptor: descriptor, size: font.pointSize)

                                    self.removeAttribute(NSFontAttributeName, range: range)
                                    self.addAttribute(NSFontAttributeName, value: newFont, range: range)
        })
    }

}
