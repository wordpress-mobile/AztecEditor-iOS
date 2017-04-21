import Foundation

extension String {

    /// Checks if the receiver has an empty paragraph at the specified index.
    ///
    /// - Parameters:
    ///     - index: the receiver's index to check
    ///
    /// - Returns: `true` if the specified index is in an empty paragraph, `false` otherwise.
    ///
    func isEmptyParagraph(at index: String.Index) -> Bool {
        return isStartOfNewLine(at: index) && isEndOfLine(at: index)
    }

    /// Checks if the receiver has an empty paragraph at the specified offset.
    ///
    /// - Parameters:
    ///     - offset: the receiver's offset to check
    ///
    /// - Returns: `true` if the specified offset is in an empty paragraph, `false` otherwise.
    ///
    func isEmptyParagraph(at offset: Int) -> Bool {

        let index = self.index(startIndex, offsetBy: offset)
        
        return isEmptyParagraph(at: index)
    }

    /// This methods verifies if the receiver string is an end-of-line character.
    ///
    /// - Returns: `true` if the receiver is an end-of-line character.
    ///
    func isEndOfLine() -> Bool {
        return self == String(.lineSeparator)
            || self == String(.newline)
            || self == String(.paragraphSeparator)
    }

    func isEndOfLine(after index: String.Index) -> Bool {
        assert(index != endIndex)

        let nextIndex = self.index(after: index)

        return isEndOfLine(at: nextIndex)
    }

    func isEndOfLine(at index: String.Index) -> Bool {
        return index == endIndex || substring(with: index ..< self.index(after: index)).isEndOfLine()
    }

    /// Checks if the location passed is the beggining of a new line.
    ///
    /// - Parameters:
    ///     - index: the index to check
    ///
    /// - Returns: true if beggining of a new line false otherwise
    ///
    func isStartOfNewLine(at index: String.Index) -> Bool {

        guard index != startIndex else {
            return true
        }

        let lowerBound = self.index(before: index)
        let upperBound = self.index(lowerBound, offsetBy: 1)
        let previousString = substring(with: lowerBound ..< upperBound)

        return previousString.isEndOfLine()
    }

    /// Checks if the location passed is the beggining of a new line.
    ///
    /// - Parameters:
    ///     - offset: the receiver's offset to check
    ///
    /// - Returns: true if beggining of a new line false otherwise
    ///
    func isStartOfNewLine(at offset: Int) -> Bool {

        let index = self.index(startIndex, offsetBy: offset)

        return isStartOfNewLine(at: index)
    }
}
