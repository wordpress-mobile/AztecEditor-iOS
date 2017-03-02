import Foundation
import UIKit


// MARK: - UIFont Traits Helpers
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
        let descriptor = shouldUseDefaultDescriptor() ? defaultFontDescriptor : fontDescriptor
        var newTraits = descriptor.symbolicTraits

        if enable {
            newTraits.insert(traits)
        } else {
            newTraits.remove(traits)
        }

        guard let newDescriptor = descriptor.withSymbolicTraits(newTraits) else {
            return self
        }

        return UIFont(descriptor: newDescriptor, size: pointSize)
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


// MARK: - Private UIFont Helpers
//
private extension UIFont {

    /// Indicates whether the Font Name is explicitly set within the Descriptor's Attributes.
    ///
    /// - Details: As per iOS 10, our Modify-Traits mechanism breaks whenever the Font Name is explicitly set.
    ///     This method is useful to determine whenever we need to fallback to the "System Font"'s
    ///     Default Descriptor (which does not include an explicit font name, and hence, the iOS 10 bug won't break).
    ///
    func shouldUseDefaultDescriptor() -> Bool {
        return fontDescriptor.fontAttributes[UIFontDescriptorNameAttribute] != nil
    }


    /// Returns the System Font's Descriptor, matching in size with the current UIFont Instance.
    ///
    var defaultFontDescriptor: UIFontDescriptor {
        return UIFont.systemFont(ofSize: pointSize).fontDescriptor
    }
}
