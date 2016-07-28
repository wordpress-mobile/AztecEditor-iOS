import Foundation
import UIKit


///
///
class FormattingDemoController: UIViewController
{

    @IBOutlet var textView: UITextView!

    ///
    ///
    class func controller() -> FormattingDemoController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        return storyboard.instantiateViewControllerWithIdentifier("FormattingDemoController") as! FormattingDemoController
    }


    override func viewDidLoad() {
        super.viewDidLoad()
        textView.delegate = self
        configureTextView()
    }


    func configureTextView() {
        if let filePath = NSBundle.mainBundle().URLForResource("SampleText", withExtension: "rtf"),
            let attrStr = try? NSAttributedString(URL: filePath, options: [:], documentAttributes: nil) {

            textView.attributedText = attrStr
        }
    }


    @IBAction func checkSelection() {
        checkBoldSelection()

//        checkUnderlineSelection()
    }

    func checkBoldSelection() {
        let storage = textView.textStorage
        guard storage.length > 0 else {
            return
        }

        let selectedRange = textView.selectedRange
        var effectiveRange = NSRange()
        let index = max(0, selectedRange.location - 1)
        let attr = storage.attribute(NSFontAttributeName, atIndex: index, longestEffectiveRange: &effectiveRange, inRange: selectedRange)

        print("------------------------------------")
        print("ATTRIBUTE : \(attr)")
        if let font = attr as? UIFont {
            if font.fontDescriptor().symbolicTraits.contains(.TraitBold) {
                print("TRAIT FOUND")
            }
        }
        print("SELECTED RANGE : \(selectedRange)")
        print("EFFECTIVE RANGE : \(effectiveRange)")
        print(" ")
    }


    func checkUnderlineSelection() {
        let storage = textView.textStorage
        let selectedRange = textView.selectedRange
        var effectiveRange = NSRange()
        let attr = storage.attribute(NSUnderlineStyleAttributeName, atIndex: selectedRange.location, longestEffectiveRange: &effectiveRange, inRange: selectedRange)

        print("------------------------------------")
        print("ATTRIBUTE : \(attr)")
        print("SELECTED RANGE : \(selectedRange)")
        print("EFFECTIVE RANGE : \(effectiveRange)")
        print(" ")
    }



    @IBAction func boldAction() {
        let selectedRange = textView.selectedRange
        // Bail if nothing is selected
        if selectedRange.length == 0 {
            return
        }

        var assigning = true

        // Examine the first character. If it is not bold we'll assign bold to the selection.
        // If the first character is bold we'll remove bold from the selection
        if let attr = textView.textStorage.attribute(NSFontAttributeName, atIndex: selectedRange.location, longestEffectiveRange: nil, inRange: selectedRange) {
            if let font = attr as? UIFont {
                assigning = !font.fontDescriptor().symbolicTraits.contains(.TraitBold)
            }
        }

        textView.textStorage.enumerateAttribute(NSFontAttributeName,
                                                inRange: selectedRange,
                                                options: [],
                                                usingBlock: { (object: AnyObject?, range: NSRange, stop: UnsafeMutablePointer<ObjCBool>) in
                                                    guard let font = object as? UIFont else {
                                                        return
                                                    }

                                                    var traits: UInt32
                                                    if assigning {
                                                        traits =  font.fontDescriptor().symbolicTraits.rawValue | UIFontDescriptorSymbolicTraits.TraitBold.rawValue

                                                    } else {
                                                        traits =  font.fontDescriptor().symbolicTraits.rawValue & ~UIFontDescriptorSymbolicTraits.TraitBold.rawValue
                                                    }

                                                    let descriptor = font.fontDescriptor().fontDescriptorWithSymbolicTraits(UIFontDescriptorSymbolicTraits(rawValue: traits))
                                                    let newFont = UIFont(descriptor: descriptor, size: font.pointSize)

                                                    self.textView.textStorage.removeAttribute(NSFontAttributeName, range: range)
                                                    self.textView.textStorage.addAttribute(NSFontAttributeName, value: newFont, range: range)
        })

    }

    @IBAction func italicAction() {
        let selectedRange = textView.selectedRange
        // Bail if nothing is selected
        if selectedRange.length == 0 {
            return
        }

        var assigning = true

        // Examine the first character. If it is not italic we'll assign bold to the selection.
        // If the first character is italic we'll remove italic from the selection
        if let attr = textView.textStorage.attribute(NSFontAttributeName, atIndex: selectedRange.location, longestEffectiveRange: nil, inRange: selectedRange) {
            if let font = attr as? UIFont {
                assigning = !font.fontDescriptor().symbolicTraits.contains(.TraitItalic)
            }
        }

        textView.textStorage.enumerateAttribute(NSFontAttributeName,
                                                inRange: selectedRange,
                                                options: [],
                                                usingBlock: { (object: AnyObject?, range: NSRange, stop: UnsafeMutablePointer<ObjCBool>) in
                                                    guard let font = object as? UIFont else {
                                                        return
                                                    }

                                                    var traits: UInt32
                                                    if assigning {
                                                        traits =  font.fontDescriptor().symbolicTraits.rawValue | UIFontDescriptorSymbolicTraits.TraitItalic.rawValue

                                                    } else {
                                                        traits =  font.fontDescriptor().symbolicTraits.rawValue & ~UIFontDescriptorSymbolicTraits.TraitItalic.rawValue
                                                    }

                                                    let descriptor = font.fontDescriptor().fontDescriptorWithSymbolicTraits(UIFontDescriptorSymbolicTraits(rawValue: traits))
                                                    let newFont = UIFont(descriptor: descriptor, size: font.pointSize)

                                                    self.textView.textStorage.removeAttribute(NSFontAttributeName, range: range)
                                                    self.textView.textStorage.addAttribute(NSFontAttributeName, value: newFont, range: range)
        })
    }

    @IBAction func underlineAction() {
        let selectedRange = textView.selectedRange
        // Bail if nothing is selected
        if selectedRange.length == 0 {
            return
        }

        // Assume we're adding an underline.
        var newStyle = NSUnderlineStyle.StyleSingle.rawValue
        if let _ = textView.textStorage.attribute(NSUnderlineStyleAttributeName, atIndex: selectedRange.location, effectiveRange: nil) {
            // But if one already exists we'll remove it.
            newStyle = NSUnderlineStyle.StyleNone.rawValue
        }
        self.textView.textStorage.removeAttribute(NSUnderlineStyleAttributeName, range: selectedRange)
        self.textView.textStorage.addAttribute(NSUnderlineStyleAttributeName, value: newStyle, range: selectedRange)

    }


    @IBAction func blockquoteAction() {

        let selectedRange = textView.selectedRange
        let storage = textView.textStorage

        let string = storage.string as NSString
        let range = NSRange(location: 0, length: string.length)
        string.enumerateSubstringsInRange(range,
                                          options: .ByParagraphs,
                                          usingBlock: { (substring, substringRange, enclosingRange, stop) in
                                            // Stop if necessary.
                                            if substringRange.location > NSMaxRange(selectedRange) {
                                                stop.memory = true
                                                return
                                            }

                                            // Bail early if the paragraph precedes the start of the selection
                                            if NSMaxRange(substringRange) < selectedRange.location {
                                                return
                                            }

                                            var r = NSRange()
                                            let pStyle = storage.attribute(NSParagraphStyleAttributeName,
                                                                           atIndex: substringRange.location,
                                                                           effectiveRange: &r)  as! NSParagraphStyle

                                            let tab:CGFloat = pStyle.headIndent == 0 ? 20 : 0

                                            let mStyle = NSMutableParagraphStyle()
                                            mStyle.setParagraphStyle(pStyle)
                                            mStyle.headIndent = tab
                                            mStyle.firstLineHeadIndent = tab
                                            
                                            storage.addAttribute(NSParagraphStyleAttributeName, value: mStyle, range: substringRange)
        })


    }




    func foo() {
//        let attributes = textView.textStorage.attribute
    }
    

}

extension FormattingDemoController : UITextViewDelegate
{
    func textViewDidChangeSelection(textView: UITextView) {
        checkSelection()
    }
}
