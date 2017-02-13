import Foundation
import UIKit


// MARK:- UIFont Traits Helpers
//
extension UIFont {

    /// Returns a new instance of the current font with its SymbolicTraits Updated.
    ///
    /// - Parameters:
    ///     - traits: Traits to be updated
    ///     - enable: Boolean indicating whether we should insert or remove the specified trait.
    ///
    /// - Returns: A new UIFont with the same descriptors as the current instance, but with its traits updated, as specified.
    ///
    func modifyTraits(_ traits: UIFontDescriptorSymbolicTraits, enable: Bool) -> UIFont {
        var newTraits = fontDescriptor.symbolicTraits

        if enable {
            newTraits.insert(traits)
        } else {
            newTraits.remove(traits)
        }

        let descriptor = fontDescriptor.withSymbolicTraits(newTraits)
        let newFont = UIFont(descriptor: descriptor!, size: pointSize)

        return newFont
    }


    /// Returns a boolean indicating if the specified trait is present in the font's descriptor
    ///
    /// - Parameters traits: Traits to be checked.
    ///
    /// - Returns: True if the specified trait was found.
    ///
    func containsTraits(_ traits: UIFontDescriptorSymbolicTraits) -> Bool {
        return fontDescriptor.symbolicTraits.contains(traits)
    }
}
