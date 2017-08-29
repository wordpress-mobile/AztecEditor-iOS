import Foundation


// MARK: - NSRange Extensions
//
extension NSRange {

    /// Checks if the receiver contains the specified range.
    ///
    /// - Parameters:
    ///     - range: the range that the receiver may or may not contain.
    ///
    /// - Returns: `true` if the receiver contains the specified range, `false` otherwise.
    ///
    func contains(_ range: NSRange) -> Bool {
        return intersect(withRange: range) == range
    }

    /// Checks if the receiver contains the specified location.
    ///
    /// - Parameters:
    ///     - range: the location that the receiver may or may not contain.
    ///
    /// - Returns: `true` if the receiver contains the specified location, `false` otherwise.
    ///
    func contains(offset: Int) -> Bool {
        return offset >= location && offset <= location + length
    }

    /// Calculates the end location for the receiver.
    ///
    /// - Returns: the requested end location
    ///
    var endLocation: Int {
        return location + length
    }

    /// Returns a range equal to the receiver extended to its right side by the specified addition
    /// value.
    ///
    /// - Parameters:
    ///     - addition: the number that will be added to the length of the range
    ///
    /// - Returns: the new range.
    ///
    func extendedRight(by addition: Int) -> NSRange {
        return NSRange(location: location, length: length + addition)
    }
    
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

    /// Offsets the receiver by the specified value.
    ///
    /// - Parameters:
    ///     - offset: the value to apply for the offset operation.
    ///
    /// - Returns: the requested range.
    ///
    func offset(by offset: Int) -> NSRange {
        return NSRange(location: location + offset, length: length)
    }

    /// Returns a range equal to the receiver shortened on its left side by the specified deduction
    /// value.
    ///
    /// - Parameters:
    ///     - deduction: the number that will be deducted from the length of the range
    ///
    /// - Returns: the new range.
    ///
    func shortenedLeft(by deduction: Int) -> NSRange {
        return NSRange(location: location + deduction, length: length - deduction)
    }

    /// Returns a range equal to the receiver shortened on its right side by the specified deduction
    /// value.
    ///
    /// - Parameters:
    ///     - deduction: the number that will be deducted from the length of the range
    ///
    /// - Returns: the new range.
    ///
    func shortenedRight(by deduction: Int) -> NSRange {
        return NSRange(location: location, length: length - deduction)
    }

    /// Returns the union with the specified range.
    ///
    /// This is `NSUnionRange` wrapped as an instance method.
    ///
    func union(withRange target: NSRange) -> NSRange {
        return NSUnionRange(self, target)
    }

    /// Returns a NSRange instance with location = 0 + length = 0
    ///
    static var zero: NSRange {
        return NSRange(location: 0, length: 0)
    }
}

extension Sequence where Iterator.Element == NSRange {
    /// Returns the union of all the ranges in the sequence
    ///
    func union() -> NSRange? {
        return reduce(nil) { (partialUnion, range) in
            guard let partialUnion = partialUnion else {
                return range
            }
            return partialUnion.union(withRange: range)
        }
    }
}

#if swift(>=3.2)
    // No Op
#else
    extension NSRange: Equatable {
        public static func ==(lhs: NSRange, rhs: NSRange) -> Bool{
            return lhs.location == rhs.location && lhs.length == rhs.length
        }
    }
#endif

