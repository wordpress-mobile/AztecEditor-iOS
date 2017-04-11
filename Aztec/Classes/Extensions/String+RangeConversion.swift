import Foundation


// MARK: - String NSRange and Location convertion Extensions
//
extension String
{
    func range(from nsRange : NSRange) -> Range<String.Index>? {
        let unicodeStart = unicodeScalars.index(unicodeScalars.startIndex, offsetBy: nsRange.location)
        let unicodeEnd = unicodeScalars.index(unicodeStart, offsetBy: nsRange.length)

        guard
            let start = unicodeStart.samePosition(in: self),
            let end = unicodeEnd.samePosition(in: self) else {
                return nil
        }

        return start ..< end
    }

    func nsRange(from range: Range<String.Index>) -> NSRange {
        let location = distance(from: startIndex, to: range.lowerBound)
        let length = distance(from: range.lowerBound, to: range.upperBound)

        return NSRange(location: location, length: length)
    }

    func indexFromLocation(_ location: Int) -> String.Index? {
        guard
            let unicodeLocation = unicodeScalars.index(unicodeScalars.startIndex, offsetBy: location, limitedBy: unicodeScalars.endIndex),
            let location = unicodeLocation.samePosition(in: self) else {
                return nil
        }

        return location
    }

    func isLastValidLocation(_ location: Int) -> Bool {
        if self.isEmpty {
            return false
        }
        return index(before: endIndex) == indexFromLocation(location)
    }

    func location(after: Int) -> Int? {
        guard let currentIndex = indexFromLocation(after), currentIndex != endIndex else {
            return nil
        }
        let afterIndex = index(after: currentIndex)
        let after16 = afterIndex.samePosition(in: utf16)
        return utf16.distance(from: utf16.startIndex, to: after16)
    }

    func location(before: Int) -> Int? {
        guard let currentIndex = indexFromLocation(before), currentIndex != startIndex else {
            return nil
        }

        let beforeIndex = index(before: currentIndex)
        let before16 = beforeIndex.samePosition(in: utf16)
        return utf16.distance(from: utf16.startIndex, to: before16)
    }

    func range(_ range: Range<String.Index>, offsetBy offset: String.IndexDistance) -> Range<String.Index> {

        let startIndex = index(range.lowerBound, offsetBy: offset)
        let endIndex = index(range.upperBound, offsetBy: offset)

        return startIndex ..< endIndex
    }
}
