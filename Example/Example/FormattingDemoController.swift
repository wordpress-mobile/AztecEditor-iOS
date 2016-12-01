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
        return storyboard.instantiateViewController(withIdentifier: "FormattingDemoController") as! FormattingDemoController
    }


    override func viewDidLoad() {
        super.viewDidLoad()
        textView.delegate = self
        configureTextView()
    }


    func configureTextView() {
        if let filePath = Bundle.main.url(forResource: "SampleText", withExtension: "rtf"),
            let attrStr = try? NSAttributedString(url: filePath, options: [:], documentAttributes: nil) {

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
        let attr = storage.attribute(NSFontAttributeName, at: index, longestEffectiveRange: &effectiveRange, in: selectedRange)

        print("------------------------------------")
        print("ATTRIBUTE : \(attr)")
        if let font = attr as? UIFont {
            if font.fontDescriptor.symbolicTraits.contains(.traitBold) {
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
        let attr = storage.attribute(NSUnderlineStyleAttributeName, at: selectedRange.location, longestEffectiveRange: &effectiveRange, in: selectedRange)

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
        if let attr = textView.textStorage.attribute(NSFontAttributeName, at: selectedRange.location, longestEffectiveRange: nil, in: selectedRange) {
            if let font = attr as? UIFont {
                assigning = !font.fontDescriptor.symbolicTraits.contains(.traitBold)
            }
        }

        textView.textStorage.enumerateAttribute(NSFontAttributeName,
                                                in: selectedRange,
                                                options: [],
                                                using: { (object: AnyObject?, range: NSRange, stop: UnsafeMutablePointer<ObjCBool>) in
                                                    guard let font = object as? UIFont else {
                                                        return
                                                    }

                                                    var traits: UInt32
                                                    if assigning {
                                                        traits =  font.fontDescriptor.symbolicTraits.rawValue | UIFontDescriptorSymbolicTraits.traitBold.rawValue

                                                    } else {
                                                        traits =  font.fontDescriptor.symbolicTraits.rawValue & ~UIFontDescriptorSymbolicTraits.traitBold.rawValue
                                                    }

                                                    let descriptor = font.fontDescriptor.withSymbolicTraits(UIFontDescriptorSymbolicTraits(rawValue: traits))
                                                    let newFont = UIFont(descriptor: descriptor!, size: font.pointSize)

                                                    self.textView.textStorage.removeAttribute(NSFontAttributeName, range: range)
                                                    self.textView.textStorage.addAttribute(NSFontAttributeName, value: newFont, range: range)
        } as! (Any?, NSRange, UnsafeMutablePointer<ObjCBool>) -> Void)

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
        if let attr = textView.textStorage.attribute(NSFontAttributeName, at: selectedRange.location, longestEffectiveRange: nil, in: selectedRange) {
            if let font = attr as? UIFont {
                assigning = !font.fontDescriptor.symbolicTraits.contains(.traitItalic)
            }
        }

        textView.textStorage.enumerateAttribute(NSFontAttributeName,
                                                in: selectedRange,
                                                options: [],
                                                using: { (object: AnyObject?, range: NSRange, stop: UnsafeMutablePointer<ObjCBool>) in
                                                    guard let font = object as? UIFont else {
                                                        return
                                                    }

                                                    var traits: UInt32
                                                    if assigning {
                                                        traits =  font.fontDescriptor.symbolicTraits.rawValue | UIFontDescriptorSymbolicTraits.traitItalic.rawValue

                                                    } else {
                                                        traits =  font.fontDescriptor.symbolicTraits.rawValue & ~UIFontDescriptorSymbolicTraits.traitItalic.rawValue
                                                    }

                                                    let descriptor = font.fontDescriptor.withSymbolicTraits(UIFontDescriptorSymbolicTraits(rawValue: traits))
                                                    let newFont = UIFont(descriptor: descriptor!, size: font.pointSize)

                                                    self.textView.textStorage.removeAttribute(NSFontAttributeName, range: range)
                                                    self.textView.textStorage.addAttribute(NSFontAttributeName, value: newFont, range: range)
        } as! (Any?, NSRange, UnsafeMutablePointer<ObjCBool>) -> Void)
    }

    @IBAction func underlineAction() {
        let selectedRange = textView.selectedRange
        // Bail if nothing is selected
        if selectedRange.length == 0 {
            return
        }

        // Assume we're adding an underline.
        var newStyle = NSUnderlineStyle.styleSingle.rawValue
        if let _ = textView.textStorage.attribute(NSUnderlineStyleAttributeName, at: selectedRange.location, effectiveRange: nil) {
            // But if one already exists we'll remove it.
            newStyle = NSUnderlineStyle.styleNone.rawValue
        }
        self.textView.textStorage.removeAttribute(NSUnderlineStyleAttributeName, range: selectedRange)
        self.textView.textStorage.addAttribute(NSUnderlineStyleAttributeName, value: newStyle, range: selectedRange)

    }


    @IBAction func blockquoteAction() {

        let selectedRange = textView.selectedRange
        let storage = textView.textStorage

        let string = storage.string as NSString
        let range = NSRange(location: 0, length: string.length)
        string.enumerateSubstrings(in: range,
                                          options: .byParagraphs,
                                          using: { (substring, substringRange, enclosingRange, stop) in
                                            // Stop if necessary.
                                            if substringRange.location > NSMaxRange(selectedRange) {
                                                stop.pointee = true
                                                return
                                            }

                                            // Bail early if the paragraph precedes the start of the selection
                                            if NSMaxRange(substringRange) < selectedRange.location {
                                                return
                                            }

                                            var r = NSRange()
                                            let pStyle = storage.attribute(NSParagraphStyleAttributeName,
                                                                           at: substringRange.location,
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
    func textViewDidChangeSelection(_ textView: UITextView) {
        checkSelection()
    }
}
