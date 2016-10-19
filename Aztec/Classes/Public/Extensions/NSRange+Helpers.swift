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

    /// Returns the union with the specified range.
    ///
    /// This is `NSUnionRange` wrapped as an instance method.
    ///
    func union(withRange target: NSRange) -> NSRange {
        return NSUnionRange(self, target)
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

extension SequenceType where Generator.Element == NSRange {
    func union() -> NSRange? {
        return reduce(nil) { (partialUnion, range) in
            guard let partialUnion = partialUnion else {
                return range
            }
            return partialUnion.union(withRange: range)
        }
    }
}
