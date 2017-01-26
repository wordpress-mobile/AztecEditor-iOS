import Foundation
import UIKit

/// Convenience extension to group font trait related methods.
///
public extension NSAttributedString
{


    /// Checks if the specified font trait exists at the specified character index.
    ///
    /// - Parameters:
    ///     - trait: A font trait.
    ///     - index: A character index.
    ///
    /// - Returns: True if found.
    ///
    public func fontTrait(_ trait: UIFontDescriptorSymbolicTraits, existsAtIndex index: Int) -> Bool {
        guard let attr = attribute(NSFontAttributeName, at: index, effectiveRange: nil) else {
            return false
        }
        if let font = attr as? UIFont {
            return font.fontDescriptor.symbolicTraits.contains(trait)
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
    public func fontTrait(_ trait: UIFontDescriptorSymbolicTraits, spansRange range: NSRange) -> Bool {
        var spansRange = true

        // Assume we're removing the trait. If the trait is missing anywhere in the range assign it.
        enumerateAttribute(NSFontAttributeName,
                           in: range,
                           options: [],
                           using: { (object: Any?, range: NSRange, stop: UnsafeMutablePointer<ObjCBool>) in
                            guard let font = object as? UIFont else {
                                return
                            }
                            if !font.fontDescriptor.symbolicTraits.contains(trait) {
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
    ///     - trait: A font trait.
    ///     - range: The NSRange to inspect
    ///
    public func toggleFontTrait(_ trait: UIFontDescriptorSymbolicTraits, range: NSRange) {
        // Bail if nothing is selected
        if range.length == 0 {
            return
        }

        let enable = !fontTrait(trait, spansRange: range)

        modifyTraits(trait, range: range, enable: enable)
    }

    fileprivate func modifyTraits(_ traits: UIFontDescriptorSymbolicTraits, range: NSRange, enable: Bool) {

        enumerateAttribute(NSFontAttributeName,
                           in: range,
                           options: [],
                           using: { (object: Any, range: NSRange, stop: UnsafeMutablePointer<ObjCBool>) in
                            guard let font = object as? UIFont else {
                                return
                            }

                            let newFont = font.modifyTraits(traits, enable: enable)

                            self.beginEditing()
                            self.removeAttribute(NSFontAttributeName, range: range)
                            self.addAttribute(NSFontAttributeName, value: newFont, range: range)
                            self.endEditing()
        })
    }
}
