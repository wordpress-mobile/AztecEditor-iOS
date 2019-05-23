import Foundation


// MARK: - Paragraph Analysis Helpers
//
public extension String {

    /// This methods verifies if the receiver string contains a new paragraph at the specified index.
    ///
    /// - Parameter index: the index to check
    ///
    /// - Returns: `true` if the receiver contains a new paragraph at the specified Index.
    ///
    func isStartOfParagraph(at index: String.Index) -> Bool {
        guard index != startIndex else {
            return true
        }

        return isEndOfParagraph(before: index)
    }


    /// This methods verifies if the receiver string contains an End of Paragraph at the specified index.
    ///
    /// - Parameter index: the index to check
    ///
    /// - Returns: `true` if the receiver contains an end-of-paragraph character at the specified Index.
    ///
    func isEndOfParagraph(at index: String.Index) -> Bool {
        guard index != endIndex else {
            return true
        }

        let endingRange = index ..< self.index(after: index)
        let endingString = compatibleSubstring(with: endingRange)
        let paragraphSeparators = [String(.carriageReturn), String(.lineFeed), String(.paragraphSeparator)]

        return paragraphSeparators.contains(endingString)
    }


    /// This methods verifies if the receiver string contains an End of Paragraph before the specified index.
    ///
    /// - Parameter index: the index to check
    ///
    /// - Returns: `true` if the receiver contains an end-of-paragraph character before the specified Index.
    ///
    func isEndOfParagraph(before index: String.Index) -> Bool {
        assert(index != startIndex)
        return isEndOfParagraph(at: self.index(before: index))
    }


    /// Checks if the receiver has an empty paragraph at the specified index.
    ///
    /// - Parameter index: the receiver's index to check
    ///
    /// - Returns: `true` if the specified index is in an empty paragraph, `false` otherwise.
    ///
    func isEmptyParagraph(at index: String.Index) -> Bool {
        return isStartOfParagraph(at: index) && isEndOfParagraph(at: index)
    }


    /// Checks if the receiver has an empty paragraph at the specified offset.
    ///
    /// - Parameter offset: the receiver's offset to check
    ///
    /// - Returns: `true` if the specified offset is in an empty line, `false` otherwise.
    ///
    func isEmptyParagraph(at offset: Int) -> Bool {
        guard let index = self.indexFromLocation(offset) else {
            return true
        }

        return isEmptyParagraph(at: index)
    }
}
