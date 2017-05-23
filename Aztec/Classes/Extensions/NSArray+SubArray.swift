import Foundation

extension Array {

    /// Creates a sub-array with the elements of the receiver within the specified indexes.
    ///
    /// - Parameters:
    ///     - startIndex: the index of the first element that will be included in the sub-array.
    ///     - endIndex: the index of the last element that will be included in the sub-array.
    ///
    /// - Returns: the requested sub-array.
    ///
    func subArray(from startIndex: Int, through endIndex: Int) -> Array {
        assert(startIndex <= endIndex)

        let leftElementsToDrop = startIndex
        let rightElementsToDrop = count - (endIndex + 1)

        let rightSlice = dropFirst(leftElementsToDrop)
        let finalSlice = rightSlice.dropLast(rightElementsToDrop)

        let subArray = type(of: self).init(finalSlice)

        return subArray
    }
}
