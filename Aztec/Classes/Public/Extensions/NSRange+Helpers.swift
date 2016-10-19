import Foundation


// MARK: - NSRange Extensions
//
extension NSRange
{
    /// Returns the intersection between the receiver and the specified range.
    ///
    /// - Important: the main difference with NSIntersectionRange is that this method considers any contact (even a
    ///         zero-length contact) as an intersection.  Another difference is that this method returns `nil`
    ///         when there's absolutely no contact.
    ///
    /// - Parameters:
    ///     - range: the range to compare the receiver against.
    ///
    /// - Returns: the interesection if there's any, or `nil` otherwise.
    ///
    func intersect(withRange target: NSRange) -> NSRange? {
        
        let endLocation = location + length
        let targetEndLocation = target.location + target.length
        
        if target.location >= location && targetEndLocation <= endLocation {
            return target
        } else if target.location < location && targetEndLocation >= location && targetEndLocation <= endLocation {
            return NSRange(location: location, length: targetEndLocation - location)
        } else if target.location >= location && target.location <= endLocation && targetEndLocation > endLocation {
            return NSRange(location: target.location, length: endLocation - target.location)
        } else if target.location < location && targetEndLocation > endLocation {
            return self
        } else {
            return nil
        }
    }

    func union(withRange target: NSRange) -> NSRange {
        return NSRange(location: min(location, target.location), endLocation: max(endLocation, target.endLocation))
    }

    init(location: Int, endLocation: Int) {
        self.location = location
        self.length = endLocation - location
    }

    /// Returns the maximum Location.
    ///
    var endLocation: Int {
        return location + length
    }

    /// Returns a NSRange instance with location = 0 + length = 0
    ///
    static var zero: NSRange {
        return NSRange(location: 0, length: 0)
    }
}
