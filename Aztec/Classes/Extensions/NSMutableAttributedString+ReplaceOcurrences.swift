import Foundation

extension NSMutableAttributedString {

    /// Replaces all ocurrences of `stringToFind` with `replacementString` in the receiver.
    ///
    /// - Parameters:
    ///     - stringToFind: the string to replace.
    ///     - replacementString: the string to replace all matching occurrences with.
    ///
    func replaceOcurrences(of stringToFind: String, with replacementString: String) {

        assert(!replacementString.contains(stringToFind),
               "Allowing the replacement string to contain the original string would result in a ininite loop.")

        while let range = string.range(of: stringToFind) {
            let nsRange = string.utf16NSRange(from: range)

            replaceCharacters(in: nsRange, with: replacementString)
        }
    }
}
