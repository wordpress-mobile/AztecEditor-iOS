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
        return RootNode(children: [TextNode(text: "")])
    }()

    // MARK: - NSTextStorage

    override public var string: String {
        return textStore.string
    }


    // MARK: - Attachments

    public func aztecTextAttachments() -> [AztecTextAttachment] {
        let range = NSMakeRange(0, length)
        var attachments = [AztecTextAttachment]()
        enumerateAttribute(NSAttachmentAttributeName, inRange: range, options: []) { (object, range, stop) in
            if let attachment = object as? AztecTextAttachment {
                attachments.append(attachment)
            }
        }

        return attachments
    }


    // MARK: - Overriden Methods

    override public func attributesAtIndex(location: Int, effectiveRange range: NSRangePointer) -> [String : AnyObject] {
        return textStore.attributesAtIndex(location, effectiveRange: range)
    }

    override public func replaceCharactersInRange(range: NSRange, withString str: String) {
        beginEditing()

        textStore.replaceCharactersInRange(range, withString: str)
        rootNode.replaceCharacters(inRange: range, withString: str)

        edited(.EditedCharacters, range: range, changeInLength: str.characters.count - range.length)

        endEditing()
    }

    override public func setAttributes(attrs: [String : AnyObject]?, range: NSRange) {
        beginEditing()

        textStore.setAttributes(attrs, range: range)
        edited(.EditedAttributes, range: range, changeInLength: 0)

        endEditing()
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

    public func setHTML(html: String, withDefaultFontDescriptor defaultFontDescriptor: UIFontDescriptor) {

        let converter = HTMLToAttributedString(usingDefaultFontDescriptor: defaultFontDescriptor)
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
                            let newFont = UIFont(descriptor: descriptor!, size: font.pointSize)

                            self.removeAttribute(NSFontAttributeName, range: range)
                            self.addAttribute(NSFontAttributeName, value: newFont, range: range)
        })
    }

}
