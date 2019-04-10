import Foundation
import UIKit


// MARK: -  Convenience extension to group font trait related methods.
//
public extension NSAttributedString {

    /// Checks if the specified font trait exists at the specified character index.
    ///
    /// - Parameters:
    ///     - traits: A font trait.
    ///     - index: A character index.
    ///
    /// - Returns: True if found.
    ///
    func fontTrait(_ traits: UIFontDescriptor.SymbolicTraits, existsAtIndex index: Int) -> Bool {
        guard let attr = attribute(.font, at: index, effectiveRange: nil) else {
            return false
        }
        if let font = attr as? UIFont {
            return font.fontDescriptor.symbolicTraits.contains(traits)
        }
        return false
    }


    /// Checks if the specified font trait spans the specified NSRange.
    ///
    /// - Parameters:
    ///     - traits: A font trait.
    ///     - range: The NSRange to inspect
    ///
    /// - Returns: True if the trait spans the entire range.
    ///
    func fontTrait(_ traits: UIFontDescriptor.SymbolicTraits, spansRange range: NSRange) -> Bool {
        var spansRange = true

        // Assume we're removing the trait. If the trait is missing anywhere in the range assign it.
        enumerateAttribute(.font,
                           in: range,
                           options: [],
                           using: { (object: Any?, range: NSRange, stop: UnsafeMutablePointer<ObjCBool>) in
                            guard let font = object as? UIFont else {
                                return
                            }
                            if !font.fontDescriptor.symbolicTraits.contains(traits) {
                                spansRange = false
                                stop.pointee = true
                            }
        })

        return spansRange
    }
}

public extension NSMutableAttributedString {

    /// Adds or removes the specified font trait within the specified range.
    ///
    /// - Parameters:
    ///     - traits: Font traits.
    ///     - range: The NSRange to inspect
    ///
    func toggle(_ fontTraits: UIFontDescriptor.SymbolicTraits, inRange range: NSRange) {
        // Bail if nothing is selected
        if range.length == 0 {
            return
        }

        let enable = !self.fontTrait(fontTraits, spansRange: range)

        modify(fontTraits, range: range, enable: enable)
    }

    fileprivate func modify(_ fontTraits: UIFontDescriptor.SymbolicTraits, range: NSRange, enable: Bool) {

        enumerateAttribute(.font,
                           in: range,
                           options: [],
                           using: { (object: Any, range: NSRange, stop: UnsafeMutablePointer<ObjCBool>) in
                            guard let font = object as? UIFont else {
                                return
                            }

                            let newFont = font.modifyTraits(fontTraits, enable: enable)

                            self.beginEditing()
                            self.removeAttribute(.font, range: range)
                            self.addAttribute(.font, value: newFont, range: range)
                            self.endEditing()
        })
    }
}
