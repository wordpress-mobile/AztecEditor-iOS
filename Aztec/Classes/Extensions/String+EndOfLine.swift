import Foundation

extension String {

    /// Checks if the receiver has an empty line at the specified index.
    ///
    /// - Parameters:
    ///     - index: the receiver's index to check
    ///
    /// - Returns: `true` if the specified index is in an empty line, `false` otherwise.
    ///
    public func isEmptyLine(at index: String.Index) -> Bool {
        return isStartOfNewLine(at: index) && isEndOfLine(at: index)
    }

    /// Checks if the receiver has an empty line at the specified offset.
    ///
    /// - Parameters:
    ///     - offset: the receiver's offset to check
    ///
    /// - Returns: `true` if the specified offset is in an empty line, `false` otherwise.
    ///
    public func isEmptyLine(at offset: Int) -> Bool {
        guard let index = self.indexFromLocation(offset) else {
            return true
        }
        
        return isEmptyLine(at: index)
    }

    /// Checks if the receiver has an empty line at the specified offset and if the offset
    /// corresponds to EOF (end-of-file).
    ///
    /// - Parameters:
    ///     - offset: the receiver's offset to check
    ///
    /// - Returns: `true` if the specified offset is in an empty paragraph, `false` otherwise.
    ///
    func isEmptyLineAtEndOfFile(at offset: Int) -> Bool {
        return offset == count && isEmptyLine(at: offset)
    }

    /// This methods verifies if the receiver string is an end-of-line character.
    ///
    /// - Returns: `true` if the receiver is an end-of-line character.
    ///
    func isEndOfLine() -> Bool {
        return self == String(.carriageReturn)
            || self == String(.lineSeparator)
            || self == String(.lineFeed)
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
        guard index != endIndex else {
            return true
        }

        let range = index ..< self.index(after: index)
        let slice = self.compatibleSubstring(with: range)

        return slice.isEndOfLine()
    }

    func isEndOfLine(atUTF16Offset utf16Offset: Int) -> Bool {
        let utf16Index = utf16.index(utf16.startIndex, offsetBy: utf16Offset)

        guard let index = utf16Index.samePosition(in: self) else {
            fatalError("This should not be possible, review your logic.")
        }

        return isEndOfLine(at: index)
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

    /// Checks if the location passed is the beggining of a new line.
    ///
    /// - Parameters:
    ///     - offset: the receiver's offset to check
    ///
    /// - Returns: true if beggining of a new line false otherwise
    ///
    func isStartOfNewLine(atUTF16Offset utf16Offset: Int) -> Bool {

        let utf16Index = utf16.index(utf16.startIndex, offsetBy: utf16Offset)

        guard let index = utf16Index.samePosition(in: self) else {
            fatalError("This should not be possible, review your logic.")
        }

        return isStartOfNewLine(at: index)
    }
}
