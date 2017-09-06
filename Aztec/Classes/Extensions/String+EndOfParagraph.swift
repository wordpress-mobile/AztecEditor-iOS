import Foundation


// MARK: - Paragraph Analysis Helpers
//
extension String {

    /// This methods verifies if the receiver string contains an End of Paragraph before the specified index.
    ///
    /// - Parameters:
    ///     - index: the index to check
    ///
    /// - Returns: `true` if the receiver contains an end-of-paragraph character before the specified Index.
    ///
    func isEndOfParagraph(before index: String.Index) -> Bool {
        assert(index != startIndex)

        let previousIndex = self.index(before: index)
        guard previousIndex != endIndex else {
            return true
        }

        let endingString = substring(with: previousIndex ..< index)
        let paragraphSeparators = [String(.carriageReturn), String(.lineFeed), String(.paragraphSeparator)]

        return paragraphSeparators.contains(endingString)
    }
}
