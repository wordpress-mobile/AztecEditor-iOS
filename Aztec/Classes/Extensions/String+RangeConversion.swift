import Foundation


// MARK: - String NSRange and Location convertion Extensions
//
extension String
{    
    func rangeFromNSRange(_ nsRange : NSRange) -> Range<String.Index>? {
        let from16 = utf16.index(utf16.startIndex, offsetBy: nsRange.location)
        let to16 = utf16.index(from16, offsetBy: nsRange.length)

        guard
            let from = from16.samePosition(in: self),
            let to = to16.samePosition(in: self)
            else { return nil }
        return from ..< to
                
    }

    func indexFromLocation(_ location: Int) -> String.Index? {
        guard
            let from16 = utf16.index(utf16.startIndex, offsetBy: location, limitedBy: utf16.endIndex),
            let from = from16.samePosition(in: self)
            else { return nil }
        return from
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
}
