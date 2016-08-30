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


    @IBAction func toggleOrderedListAction() {
        listActions(.Ordered)
    }


    @IBAction func toggleUnorderedListAction() {
        listActions(.Unordered)
    }


    // MARK: - LIST WRANGLING


    func listActions(type: TextListType) {
        // get selected paragraph ranges
        let ranges = selectedParagraphRanges()
        guard let firstRange = ranges.first else {
            return
        }

        // Check first paragraphs attributes
        if let style = textListAttributeAtIndex(firstRange.location) {
            // What kind of list is this?
            if style.type == type {
                removeTextListAttributeAtRanges(ranges)

            } else {
                // For different type of list, we'll change the list style (for the whole list).
                updateListAtIndex(firstRange.location, withListType: type)
            }

        } else {
            // Not already a list.  Add the list style.

            // Check the paragraphs at each range. If any have the opposite list style remove that range.
            let filtered = ranges.filter({ (range) -> Bool in
                if let attr = textListAttributeAtIndex(range.location) {
                    if attr.type != type {
                        return false
                    }
                }
                return true
            })

            applyTextListAttribute(type, atParagraphRanges: filtered)
        }   
    }


    func selectedParagraphRanges() -> [NSRange] {
        return paragraphRangesSpanningRange(textView.selectedRange)
    }


    func paragraphRangesSpanningRange(range: NSRange) -> [NSRange] {
        var paragraphRanges = [NSRange]()
        let storage = textView.textStorage
        let string = storage.string as NSString
        string.enumerateSubstringsInRange(NSRange(location: 0, length: string.length),
                                          options: .ByParagraphs,
                                          usingBlock: { (substring, substringRange, enclosingRange, stop) in
                                            // Stop if necessary.
                                            if enclosingRange.location >= NSMaxRange(range) {
                                                stop.memory = true
                                                return
                                            }

                                            // Bail early if the paragraph precedes the start of the selection
                                            if NSMaxRange(enclosingRange) <= range.location {
                                                return
                                            }

                                            paragraphRanges.append(enclosingRange)
        })
        return paragraphRanges
    }


    func textListAttributeAtIndex(index: Int) -> TextList? {
        let storage = textView.textStorage
        return storage.attribute(TextList.attributeName, atIndex: index, effectiveRange: nil) as? TextList
    }


    func applyTextListAttribute(type: TextListType, atParagraphRanges ranges:[NSRange]) {
        if ranges.count == 0 {
            return
        }

        // Mutable ranges
        var ranges = ranges

        guard
            let firstRange = ranges.first,
            let lastRange = ranges.last
            else {
                return
        }

        //- check preceding paragraph style for same kind of list & same list level.  If found add those paragraph ranges.
        var index = firstRange.location - 1
        ranges = addParagraphRangesForListOfType(type, atIndex: index, toArray: ranges)


        //- check following paragraph style for same kind of list & same list level. If found add those paragraph ranges.
        index = NSMaxRange(lastRange)
        ranges = addParagraphRangesForListOfType(type, atIndex: index, toArray: ranges)

        let startingLocation = ranges.first!.location
        var length = 0
        let storage = textView.textStorage
        storage.beginEditing()
        //- Filter out other elements (blockquote, p, h1, h2, h3, etc.) from each paragraph. Each “paragraph” should be vanilla
        // TODO:


        //- Iterate over affected paragraphs in reverse order.  Insert/replace list marker (attributes) into string and assign list item.
        for (idx, range) in ranges.enumerate().reverse() {
            let str = storage.attributedSubstringFromRange(range)
            let mstr = setTextListItemStyleForType(type, toString: str, itemIndex: idx + 1)
            length += mstr.length
            storage.replaceCharactersInRange(range, withAttributedString: mstr)
        }

        let listRange = NSRange(location: startingLocation, length: length)
        //- set list type attribute for whole list
        let textList = TextList()
        textList.type = type
        storage.addAttribute(TextList.attributeName, value: textList, range: listRange)


        storage.endEditing()

        if textView.selectedRange.length > 0 {
            textView.selectedRange = listRange
        }
    }


    func setTextListItemStyleForType(type: TextListType, toString string: NSAttributedString, itemIndex index: Int) -> NSAttributedString {
        let mStr = NSMutableAttributedString(attributedString: string)

        // Remove any existing list marker.
        if mStr.length > 0 {
            let strRange = NSRange(location: 0, length: mStr.length)
            var markerRange = NSRange()
            if let _ = mStr.attribute(TextListItemMarker.attributeName, atIndex: 0, longestEffectiveRange: &markerRange, inRange: strRange) {
                mStr.removeAttribute(TextListItemMarker.attributeName, range: markerRange)
                mStr.replaceCharactersInRange(markerRange, withString: "")
            }
        }

        // TODO: Need to accomodate RTL languages too. 

        // Add the correct list marker. (Tabs aren't really reliable for spacing. Need a better solution.)
        let marker = type == .Ordered ? "\(index).\t" : "\u{2022}\t\t"

        let listMarker = NSAttributedString(string: marker, attributes: [TextListItemMarker.attributeName: TextListItemMarker()])
        mStr.insertAttributedString(listMarker, atIndex: 0)

        // Set the attributes for the list item style
        // TODO: Need to be smarter about indents so we take into account nested lists. Need to figure out tabstops also.
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.firstLineHeadIndent = 0
        paragraphStyle.headIndent = 16 // TODO: Need to get whatever the actual tab width is, and use that as a multiplier.  Maybe we can limit the tab width also?
        // TODO: Quick and dirty just so we can have some control.  Need to clean this up and do it better.
        paragraphStyle.tabStops = [
            NSTextTab(textAlignment: .Natural, location: 8, options: [String : AnyObject]()),
            NSTextTab(textAlignment: .Natural, location: 16, options: [String : AnyObject]()),
            NSTextTab(textAlignment: .Natural, location: 24, options: [String : AnyObject]()),
            NSTextTab(textAlignment: .Natural, location: 32, options: [String : AnyObject]()),
            NSTextTab(textAlignment: .Natural, location: 64, options: [String : AnyObject]()),
        ]
        let attributes = [
            TextListItem.attributeName: TextListItem(),
            NSParagraphStyleAttributeName: paragraphStyle
        ] as [String: AnyObject]

        // TODO: Make sure that the spacing between bullets is correct, not too much extra space.
//        paragraphStyle.paragraphSpacing = 0

        mStr.addAttributes(attributes, range: NSRange(location: 0, length: mStr.length))

        // return the formatted string
        return mStr
    }


    func addParagraphRangesForListOfType(type: TextListType, atIndex index: Int, toArray ranges:[NSRange]) -> [NSRange] {
        let storage = textView.textStorage
        if index < 0 || index >= storage.length {
            return ranges
        }


        var listRange = NSRange()
        guard let attr = storage.attribute(TextList.attributeName, atIndex: index, longestEffectiveRange: &listRange, inRange: NSRange(location: 0, length: storage.length)) as? TextList
//        guard let attr = storage.attribute(TextList.attributeName, atIndex: index, effectiveRange: &listRange) as? TextList
            where attr.type == type
            else {
                return ranges
        }

        var adjustedRanges = ranges

        // Get the paragraph ranges of the list
        let paragraphRanges = paragraphRangesSpanningRange(listRange)

        // Add any new ranges
        for rng in paragraphRanges {
            if !adjustedRanges.contains({ NSEqualRanges($0, rng)}) {
                adjustedRanges.append(rng)
            }
        }

        // Make sure the ranges are sorted in ascending order
        adjustedRanges.sortInPlace { (rng1, rng2) -> Bool in
            rng1.location < rng2.location
        }

        return adjustedRanges
    }


    func removeTextListAttributeAtRanges(ranges: [NSRange]) {
        guard let firstRange = ranges.first else {
            return
        }

        var listRangeLength = 0
        for range in ranges {
            listRangeLength += range.length
        }
        let fullRange = NSRange(location: firstRange.location, length: listRangeLength)


        let storage = textView.textStorage

        storage.removeAttribute(TextList.attributeName, range: fullRange)
        storage.removeAttribute(TextListItem.attributeName, range: fullRange)

        // For the same type of list, we'll remove the list style. A bit tricky.  We need to remove the style
        // (and attributes) from the selected paragraph ranges, then if the following range was an ordered list,
        // we need to update its markers. (Maybe some other attribute clean up?)

        var length = 0
        //- Iterate over affected paragraphs in reverse order.  Remove list marker and attributes
        for range in ranges.reverse() {
            let str = storage.attributedSubstringFromRange(range)
            let mstr = removeTextListItemStyleFromString(str)
            length += mstr.length
            storage.replaceCharactersInRange(range, withAttributedString: mstr)
        }

        let adjustedRange = NSRange(location: firstRange.location, length: length)
        storage.fixAttributesInRange(adjustedRange)


        // Update the following list if necessary.

        let followingIdx = NSMaxRange(adjustedRange) + 1 // Add two. if just one we're pointing at the newline character and we'll end up captureing the paragraph range we just edited.
        if followingIdx < storage.length {

            if let attr = textListAttributeAtIndex(followingIdx) {
                updateListAtIndex(followingIdx, withListType: attr.type)
            }
        }

        if textView.selectedRange.length > 0 {
            textView.selectedRange = adjustedRange
        }

    }

    func removeTextListItemStyleFromString(str: NSAttributedString) -> NSAttributedString {
        let mstr = NSMutableAttributedString(attributedString: str)

        let range = NSRange(location: 0, length: mstr.length)
        mstr.removeAttribute(TextList.attributeName, range: range)
        mstr.removeAttribute(TextListItem.attributeName, range: range)
        mstr.removeAttribute(NSParagraphStyleAttributeName, range: range)

        // TODO: Might need to account for other indentation.
        let paragraphStyle = NSParagraphStyle()
        mstr.addAttribute(NSParagraphStyleAttributeName, value: paragraphStyle, range: range)

        var markerRange = NSRange()
        if let _ = mstr.attribute(TextListItemMarker.attributeName, atIndex: 0, longestEffectiveRange: &markerRange, inRange: range) {
            mstr.replaceCharactersInRange(markerRange, withString: "")
        }

        return mstr
    }


    func updateListAtIndex(index: Int, withListType type: TextListType) {
        // For different type of list, we'll change the list style (for the whole list).
        var listRange = NSRange()
        let storage = textView.textStorage
        // TODO: Confirm using longest effective range is actually safe. We don't want to consume neighboring lists of a different type. (NOTE: probably not an issue when searching for custom aztec markup attributes?)
        if let _ = storage.attribute(TextList.attributeName, atIndex: index, longestEffectiveRange: &listRange, inRange: NSRange(location: 0, length: storage.length)) {
            let paragraphRanges = paragraphRangesSpanningRange(listRange)
            applyTextListAttribute(type, atParagraphRanges: paragraphRanges)
        }
    }

}

extension FormattingDemoController : UITextViewDelegate
{
    func textViewDidChangeSelection(textView: UITextView) {
//        checkSelection()
    }
}






// Encompases the whole text list. Analogous to a UL or OL tag
class TextList
{
    static let attributeName = "TextListAttributeName"
    var type = TextListType.Ordered
    var parentList: TextList?
}


// Encompases the entirety of a single text list item. Analogous to an LI tag
class TextListItem
{
    static let attributeName = "TextListItemAttributeName"

}


// Encompases the range of the bullet/number + tab.
class TextListItemMarker
{
    static let attributeName = "TextListItemMarkerAttributeName"
}


enum TextListType
{
    case Ordered
    case Unordered
}


