import Foundation
import UIKit


// MARK:- UIFont Traits Helpers
//
extension UIFont {

    /// Returns a new instance of the current font with its SymbolicTraits Updated.
    ///
    /// - Parameters:
    ///     - trait: Trait to be updated
    ///     - enable: Boolean indicating whether we should insert or remove the specified trait.
    ///
    /// - Returns: A new UIFont with the same descriptors as the current instance, but with its traits updated, as specified.
    ///
    func modifyTrait(_ trait: UIFontDescriptorSymbolicTraits, enable: Bool) -> UIFont {
        var newTraits = fontDescriptor.symbolicTraits

        if enable {
            newTraits.insert(trait)
        } else {
            newTraits.remove(trait)
        }

        let descriptor = fontDescriptor.withSymbolicTraits(newTraits)
        let newFont = UIFont(descriptor: descriptor!, size: pointSize)

        return newFont
    }
}
