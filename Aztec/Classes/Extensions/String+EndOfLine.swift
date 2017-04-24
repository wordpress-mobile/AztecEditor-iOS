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

    /// Checks if the receiver has an empty paragraph at the specified offset and if the offset
    /// corresponds to EOF (end-of-file).
    ///
    /// - Parameters:
    ///     - offset: the receiver's offset to check
    ///
    /// - Returns: `true` if the specified offset is in an empty paragraph, `false` otherwise.
    ///
    func isEmptyParagraphAtEndOfFile(at offset: Int) -> Bool {
        return offset == characters.count && isEmptyParagraph(at: offset)
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

    func isEndOfLine(before index: String.Index) -> Bool {
        assert(index != startIndex)

        let previousIndex = self.index(before: index)

        return isEndOfLine(at: previousIndex)
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

        return isEndOfLine(before: index)
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
