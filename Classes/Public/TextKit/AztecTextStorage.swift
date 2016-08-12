import Foundation


/// Custom NSTextStorage
///
public class AztecTextStorage: NSTextStorage {

    typealias ElementNode = Libxml2.HTML.ElementNode
    typealias TextNode = Libxml2.HTML.TextNode

    private var textStore = NSMutableAttributedString(string: "", attributes: nil)

    // MARK: - NSTextStorage

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

    // MARK: - Styles

    func toggleBold(range: NSRange) {

        let enable = !fontTrait(.TraitBold, spansRange: range)

        modifyTrait(.TraitBold, range: range, enable: enable)

        if enable {
            enableBoldInDOM(range)
        } else {
            //    disableBoldInDom(range)
        }
    }

    // MARK: - DOM

    private func enableBoldInDOM(range: NSRange) {
        wrap(range: range, inNodeNamed: "strong")
    }

    private func wrap(range newNodeRange: NSRange, inNodeNamed newNodeName: String) {

        let textNodes = rootNode().textNodesWrapping(newNodeRange)

        for (node, range) in textNodes {
            guard let parent = node.parent,
                let nodeIndex = parent.children.indexOf(node) else {

                assertionFailure("This scenario should not be possible. Review the logic.")
                continue
            }

            let nodeLength = node.length()

            if range.length != nodeLength {
                guard let swiftRange = node.text.rangeFromNSRange(range) else {
                    assertionFailure("This scenario should not be possible. Review the logic.")
                    continue
                }

                let preRange = Range(start: node.text.startIndex, end: swiftRange.startIndex)
                let postRange = Range(start: swiftRange.endIndex, end: node.text.endIndex)

                if postRange.count > 0 {
                    let newNode = TextNode(text: node.text.substringWithRange(postRange))

                    node.text.removeRange(postRange)
                    parent.children.insert(newNode, atIndex: nodeIndex + 1)
                }

                if preRange.count > 0 {
                    let newNode = TextNode(text: node.text.substringWithRange(preRange))

                    node.text.removeRange(preRange)
                    parent.children.insert(newNode, atIndex: nodeIndex)
                }
            }

            node.wrapInNewNode(named: newNodeName)
        }
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
