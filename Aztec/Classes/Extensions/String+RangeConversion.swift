import Foundation


// MARK: - String Extensions
//
extension String
{    
    func rangeFromNSRange(_ nsRange : NSRange) -> Range<String.Index>? {
        
        let rangeStartIndex = utf16.startIndex.advanced(by: nsRange.location)
        let rangeEndIndex = rangeStartIndex.advanced(by: nsRange.length)
        
        if let from = String.Index(rangeStartIndex, within: self),
            let to = String.Index(rangeEndIndex, within: self) {
            return from ..< to
        }
        
        return nil
    }
}
