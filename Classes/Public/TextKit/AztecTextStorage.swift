import Foundation


/// Custom NSTextStorage
///
public class AztecTextStorage: NSTextStorage {

    typealias ElementNode = Libxml2.ElementNode
    typealias TextNode = Libxml2.TextNode
    typealias RootNode = Libxml2.RootNode

    /// Element names for bold.
    ///
    /// - Note: The first element name is the preferred one.
    ///
    private static let elementNamesForBold = ["b", "strong"]

    /// Element names for italic.
    ///
    /// - Note: The first element name is the preferred one.
    ///
    private static let elementNamesForItalic = ["em", "i"]

    /// Element names for strikethrough.
    ///
    /// - Note: The first element name is the preferred one.
    ///
    private static let elementNamesForStrikethrough = ["s", "strike"]

    /// Element names for underline.
    ///
    /// - Note: The first element name is the preferred one.
    ///
    private static let elementNamesForUnderline = ["u"]

    private var textStore = NSMutableAttributedString(string: "", attributes: nil)

    private var rootNode: RootNode = {
        return RootNode(children: [])
    }()

    // MARK: - NSTextStorage

    public override var string: String {
        return textStore.string
    }


    public override func attributesAtIndex(location: Int, effectiveRange range: NSRangePointer) -> [String : AnyObject] {
        return textStore.attributesAtIndex(location, effectiveRange: range)
    }


    public override func replaceCharactersInRange(range: NSRange, withAttributedString attrString: NSAttributedString) {
        // NOTE: Hook in any custom editing here, then call super.
        // It is safe to query information about the current state the textStore,
        // However, no changes should be made.
        // Call super passing the adjusted range and attrString.
        var adjustedRange = range
        var adjustedAttrStr = NSMutableAttributedString(attributedString: attrString)
        let storageRange = NSRange(location: 0, length: length)


        // Ensure that custom attributes are correctly applied to newly typed characters.
        // NOTE: Some attributes should *not* be propigated this way.  We'll need to 
        // decide on a consistent way of identifying and filtering such attributes.
        if range.location > 0 && range.length == 0 && attrString.length == 1 {
            var previousAttributes = attributesAtIndex(range.location - 1, effectiveRange: nil)
            // Remove non-propigating attributes.
            previousAttributes.removeValueForKey(TextListItemMarker.attributeName)
            adjustedAttrStr.addAttributes(previousAttributes, range: NSRange(location: 0, length: attrString.length))
        }


        // Special handling for carriage returns
        if attrString.string == "\n" && range.location > 0 {

            var listRange = NSRange()
            if let textListAttr = attribute(TextList.attributeName, atIndex: range.location - 1,  longestEffectiveRange: &listRange, inRange: storageRange) as? TextList {
                var number = 0
                var remainderListAttr = textListAttr

                var effectiveRange = NSRange()

                // If the preceding text was an "empty" list marker, delete that marker and create a new paragraph.
                // If not create and insert a new list marker of the appropriate type.
                if let markerAttr = attribute(TextListItemMarker.attributeName, atIndex: range.location - 1, longestEffectiveRange: &effectiveRange, inRange: storageRange) as? TextListItemMarker {
                    // Remove the preceding marker and let this be a new paragraph.
                    // TODO: This needs to be whatever default paragraph style we decide on for the editor.
                    let paragraphStyle = NSParagraphStyle()
                    adjustedAttrStr.setAttributedString(NSAttributedString(string: "\n", attributes: [NSParagraphStyleAttributeName : paragraphStyle]))
                    adjustedRange = NSUnionRange(adjustedRange, effectiveRange)

                    // The remainder (if any) will be a new list of the same type starting at 1
                    remainderListAttr = TextList()
                    remainderListAttr.type = textListAttr.type
                    number = 1

                } else if let itemAttr = attribute(TextListItem.attributeName, atIndex: range.location - 1, effectiveRange: &effectiveRange) as? TextListItem {
                    number = itemAttr.number + 1
                }

                // Finally update the remainder of the list (if any)
                if let items = ListFormatter().listContentsInString(self, followingIndex: NSMaxRange(range) + 1) {
                    let remainingItems = NSMutableAttributedString(attributedString: attrString)
                    remainingItems.appendAttributedString(items)
                    ListFormatter().applyTextList(remainderListAttr, toAttributedString: remainingItems, startingNumber: number)

                    adjustedAttrStr.appendAttributedString(remainingItems)
                    adjustedRange.length += remainingItems.length
                }
            }
        }

        // Special handling for backspaces/delete
        if attrString.length == 0 {

            var listRange = NSRange()
            if let textListAttr = attribute(TextList.attributeName, atIndex: range.location - 1,  longestEffectiveRange: &listRange, inRange: storageRange) as? TextList {

                // Check if this would intersect a list marker. If so, delete the
                // entire list marker and reorder the remaining list.
                var markerRange = NSRange()
                if let markerAttr = attribute(TextListItemMarker.attributeName, atIndex: range.location, longestEffectiveRange: &markerRange, inRange: storageRange) as? TextListItemMarker {
                    var itemNumber = 1

                    // The adjusted range is the range of the marker + the previous carriage return.
                    adjustedRange = NSRange(location: markerRange.location - 1, length: markerRange.length + 1)

                    // Now see if we need to make any other adjustments to the list as a consequence of deleting the marker.
                    var adjustedList = NSMutableAttributedString()

                    // Get the previous list item (if there was one.  We need its number to reorder any following list items
                    // and to merge any remainder of the present list item.
                    var previousItemRange = NSRange()
                    if let listItem = attribute(TextListItem.attributeName, atIndex: adjustedRange.location, longestEffectiveRange: &previousItemRange, inRange: storageRange) as? TextListItem {
                        itemNumber = listItem.number
                        adjustedList.appendAttributedString(attributedSubstringFromRange(previousItemRange))

                        // The adjusted range must take into account the list item.
                        adjustedRange = NSUnionRange(adjustedRange, previousItemRange)
                    }

                    // Now get any remainder of the list.
                    if let listRemainder = ListFormatter().listContentsInString(self, followingIndex: range.location + 2
                        ) where listRemainder.length > 0 {
                        adjustedList.appendAttributedString(listRemainder)
                        adjustedRange.length += listRemainder.length
                    }

                    // Update the the list items.
                    if adjustedList.length > 0 {
                        ListFormatter().applyTextList(textListAttr, toAttributedString: adjustedList, startingNumber: itemNumber)
                    }

                    // Finally, update our adjusted attributed stirng with the adjusted list.
                    // The adjusted range should have already been updated.
                    adjustedAttrStr.setAttributedString(adjustedList)
                }

            }

        }

        super.replaceCharactersInRange(adjustedRange, withAttributedString: adjustedAttrStr)
    }


    public override func replaceCharactersInRange(range: NSRange, withString str: String) {
        beginEditing()

        textStore.replaceCharactersInRange(range, withString: str)
        rootNode.replaceCharacters(inRange: range, withString: str)

        edited(.EditedCharacters, range: range, changeInLength: (str as NSString).length - range.length)

        endEditing()
    }


    public override func setAttributes(attrs: [String : AnyObject]?, range: NSRange) {
        beginEditing()

        textStore.setAttributes(attrs, range: range)
        edited(.EditedAttributes, range: range, changeInLength: 0)

        endEditing()
    }


    public override func processEditing() {
        // Edits have happened and are about to be implemented.
        // Do any last minute changes here *BEFORE* calling super.

        super.processEditing()
    }


    // MARK: - Styles

    func toggleBold(range: NSRange) {

        let enable = !fontTrait(.TraitBold, spansRange: range)

        modifyTrait(.TraitBold, range: range, enable: enable)

        if enable {
            enableBoldInDOM(range)
        } else {
            disableBoldInDom(range)
        }
    }

    func toggleItalic(range: NSRange) {

        let enable = !fontTrait(.TraitItalic, spansRange: range)

        modifyTrait(.TraitItalic, range: range, enable: enable)

        if enable {
            enableItalicInDOM(range)
        } else {
            disableItalicInDom(range)
        }
    }

    func toggleStrikethrough(range: NSRange) {
        toggleAttribute(NSStrikethroughStyleAttributeName, value: NSUnderlineStyle.StyleSingle.rawValue, range: range, onEnable: enableStrikethroughInDOM, onDisable: disableStrikethroughInDom)
    }

    /// Toggles underline for the specified range.
    ///
    /// - Note: A better name would have been `toggleUnderline` but it was clashing with a method
    ///     in the parent class.
    ///
    /// - Note: This is a bit tricky as we can collide with a link style.  We'll want to check for
    ///     that and correct the style if necessary.
    ///
    /// - Parameters:
    ///     - range: the range to toggle the style of.
    ///
    func toggleUnderlineForRange(range: NSRange) {
        toggleAttribute(NSUnderlineStyleAttributeName, value: NSUnderlineStyle.StyleSingle.rawValue, range: range, onEnable: enableUnderlineInDOM, onDisable: disableUnderlineInDom)
    }

    private func toggleAttribute(attributeName: String, value: AnyObject, range: NSRange, onEnable: (NSRange) -> Void, onDisable: (NSRange) -> Void) {

        var effectiveRange = NSRange()
        let enable = attribute(attributeName, atIndex: range.location, effectiveRange: &effectiveRange) == nil
            || !NSEqualRanges(range, effectiveRange)

        if enable {
            addAttribute(attributeName, value: value, range: range)
            onEnable(range)
        } else {
            removeAttribute(attributeName, range: range)
            onDisable(range)
        }
    }

    // MARK: - DOM

    private func disableBoldInDom(range: NSRange) {
        rootNode.unwrap(range: range, fromElementsNamed: self.dynamicType.elementNamesForBold)
    }

    private func disableItalicInDom(range: NSRange) {
        rootNode.unwrap(range: range, fromElementsNamed: self.dynamicType.elementNamesForItalic)
    }

    private func disableStrikethroughInDom(range: NSRange) {
        rootNode.unwrap(range: range, fromElementsNamed: self.dynamicType.elementNamesForStrikethrough)
    }

    private func disableUnderlineInDom(range: NSRange) {
        rootNode.unwrap(range: range, fromElementsNamed: self.dynamicType.elementNamesForUnderline)
    }

    private func enableBoldInDOM(range: NSRange) {

        enableInDom(
            self.dynamicType.elementNamesForBold[0],
            inRange: range,
            equivalentElementNames: self.dynamicType.elementNamesForBold)
    }

    private func enableInDom(elementName: String, inRange range: NSRange, equivalentElementNames: [String]) {
        rootNode.wrapChildren(
            intersectingRange: range,
            inNodeNamed: elementName,
            withAttributes: [],
            equivalentElementNames: equivalentElementNames)
    }

    private func enableItalicInDOM(range: NSRange) {

        enableInDom(
            self.dynamicType.elementNamesForItalic[0],
            inRange: range,
            equivalentElementNames: self.dynamicType.elementNamesForItalic)
    }

    private func enableStrikethroughInDOM(range: NSRange) {

        enableInDom(
            self.dynamicType.elementNamesForStrikethrough[0],
            inRange: range,
            equivalentElementNames: self.dynamicType.elementNamesForStrikethrough)
    }

    private func enableUnderlineInDOM(range: NSRange) {

        enableInDom(
            self.dynamicType.elementNamesForUnderline[0],
            inRange: range,
            equivalentElementNames: self.dynamicType.elementNamesForUnderline)
    }

    // MARK: - HTML Interaction

    public func getHTML() -> String {
        let converter = Libxml2.Out.HTMLConverter()
        let html = converter.convert(rootNode)

        return html
    }

    public func setHTML(html: String) {

        let converter = HTMLToAttributedString(usingDefaultFontDescriptor: UIFont.systemFontOfSize(12).fontDescriptor())
        let output: (rootNode: RootNode, attributedString: NSAttributedString)

        do {
            output = try converter.convert(html)
        } catch {
            fatalError("Could not convert the HTML.")
        }

        let originalLength = textStore.length
        textStore = NSMutableAttributedString(attributedString: output.attributedString)
        edited([.EditedCharacters], range: NSRange(location: 0, length: originalLength), changeInLength: textStore.length - originalLength)
        rootNode = output.rootNode
    }
}


/// Convenience extension to group font trait related methods.
///
public extension AztecTextStorage
{


    /// Checks if the specified font trait exists at the specified character index.
    ///
    /// - Parameters:
    ///     - trait: A font trait.
    ///     - index: A character index.
    ///
    /// - Returns: True if found.
    ///
    public func fontTrait(trait: UIFontDescriptorSymbolicTraits, existsAtIndex index: Int) -> Bool {
        guard let attr = attribute(NSFontAttributeName, atIndex: index, effectiveRange: nil) else {
            return false
        }
        if let font = attr as? UIFont {
            return font.fontDescriptor().symbolicTraits.contains(trait)
        }
        return false
    }


    /// Checks if the specified font trait spans the specified NSRange.
    ///
    /// - Parameters:
    ///     - trait: A font trait.
    ///     - range: The NSRange to inspect
    ///
    /// - Returns: True if the trait spans the entire range.
    ///
    public func fontTrait(trait: UIFontDescriptorSymbolicTraits, spansRange range: NSRange) -> Bool {
        var spansRange = true

        // Assume we're removing the trait. If the trait is missing anywhere in the range assign it.
        enumerateAttribute(NSFontAttributeName,
                           inRange: range,
                           options: [],
                           usingBlock: { (object: AnyObject?, range: NSRange, stop: UnsafeMutablePointer<ObjCBool>) in
                            guard let font = object as? UIFont else {
                                return
                            }
                            if !font.fontDescriptor().symbolicTraits.contains(trait) {
                                spansRange = false
                                stop.memory = true
                            }
        })

        return spansRange
    }


    /// Adds or removes the specified font trait within the specified range.
    ///
    /// - Parameters:
    ///     - trait: A font trait.
    ///     - range: The NSRange to inspect
    ///
    public func toggleFontTrait(trait: UIFontDescriptorSymbolicTraits, range: NSRange) {
        // Bail if nothing is selected
        if range.length == 0 {
            return
        }

        let enable = !fontTrait(trait, spansRange: range)

        modifyTrait(trait, range: range, enable: enable)
    }

    private func modifyTrait(trait: UIFontDescriptorSymbolicTraits, range: NSRange, enable: Bool) {
        enumerateAttribute(NSFontAttributeName,
                           inRange: range,
                           options: [],
                           usingBlock: { (object: AnyObject?, range: NSRange, stop: UnsafeMutablePointer<ObjCBool>) in
                            guard let font = object as? UIFont else {
                                return
                            }

                            var newTraits = font.fontDescriptor().symbolicTraits

                            if enable {
                                newTraits.insert(trait)
                            } else {
                                newTraits.remove(trait)
                            }

                            let descriptor = font.fontDescriptor().fontDescriptorWithSymbolicTraits(newTraits)
                            let newFont = UIFont(descriptor: descriptor, size: font.pointSize)

                            self.removeAttribute(NSFontAttributeName, range: range)
                            self.addAttribute(NSFontAttributeName, value: newFont, range: range)
        })
    }

}
