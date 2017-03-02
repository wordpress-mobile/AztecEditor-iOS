import Foundation


// MARK: - String Extensions
//
extension String
{    
    func rangeFromNSRange(_ nsRange : NSRange) -> Range<String.Index>? {
        
        guard
            let from16 = utf16.index(utf16.startIndex, offsetBy: nsRange.location, limitedBy: utf16.endIndex),
            let to16 = utf16.index(from16, offsetBy: nsRange.length, limitedBy: utf16.endIndex),
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
        return index(before: endIndex) == indexFromLocation(location)
    }
}
