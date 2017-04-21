import Foundation

extension NSAttributedString {

    /// Convenience initializer for text replacement in an `NSAttributedString`.
    ///
    /// - Parameters:
    ///     - stringToFind: the string to replace.
    ///     - replacementString: the string to replace all matching occurrences with.
    ///
    convenience init(with attributedString: NSAttributedString, replacingOcurrencesOf string: String, with replacementString: String) {

        let mutableString = attributedString.mutableCopy() as! NSMutableAttributedString

        mutableString.replaceOcurrences(of: string, with: replacementString)

        self.init(attributedString: mutableString)
    }
}
