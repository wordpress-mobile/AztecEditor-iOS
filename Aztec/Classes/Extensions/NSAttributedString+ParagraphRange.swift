import Foundation
import UIKit

/// Functions for paragraph enumeration and identification.
///
extension NSAttributedString {
    
    /// The range of a paragraph with and without its closing separator.
    ///
    typealias ParagraphRange = (rangeExcludingParagraphSeparator: NSRange, rangeIncludingParagraphSeparator: NSRange)
    
    /// Given a range within the receiver, this method returns an array of ranges for each
    /// paragraph that intercects the provided range.
    ///
    /// - Parameters:
    ///     - range: The initial range that paragraphs must intersect to qualify as valid results.
    ///     - includeParagraphSeparator: If `true` the resulting range will also include the closing
    ///             delimiter of intersecting paragraphs.
    ///
    /// - Returns: An array of `NSRange` objects describing the ranges of each paragraph
    ///         that intersects the input range.
    ///
    func paragraphRanges(intersecting range: NSRange, includeParagraphSeparator: Bool = true) -> [NSRange] {
        var paragraphRanges = [NSRange]()
        let swiftRange = string.range(fromUTF16NSRange: range)
        let paragraphsRange = string.paragraphRange(for: swiftRange)
        
        string.enumerateSubstrings(in: paragraphsRange, options: .byParagraphs) { [unowned self] (substring, substringRange, enclosingRange, stop) in
            let paragraphRange = includeParagraphSeparator ? enclosingRange : substringRange
            paragraphRanges.append(self.string.utf16NSRange(from: paragraphRange))
        }
        
        return paragraphRanges
    }
    
    /// Given a range within the receiver, this method returns an array of ranges for each
    /// paragraph that intercects the provided range.
    ///
    /// - Parameters:
    ///     - range: The initial range that paragraphs must intersect to qualify as valid results.
    ///
    /// - Returns: An array of `ParagraphRange` objects describing the range and the enclosing range
    ///     of each paragraph that intersects the input range.
    ///
    func paragraphRanges(intersecting range: NSRange) -> ([ParagraphRange]) {
        var paragraphRanges = [ParagraphRange]()
        let swiftRange = string.range(fromUTF16NSRange: range)
        let paragraphsRange = string.paragraphRange(for: swiftRange)
        
        string.enumerateSubstrings(in: paragraphsRange, options: .byParagraphs) { [unowned self] (substring, substringRange, enclosingRange, stop) in
            let substringNSRange = self.string.utf16NSRange(from: substringRange)
            let enclosingNSRange = self.string.utf16NSRange(from: enclosingRange)
            
            paragraphRanges.append((substringNSRange, enclosingNSRange))
        }
        
        return paragraphRanges
    }
    
    /// Returns the range of characters representing the paragraph or paragraphs containing a given range.
    ///
    /// This is an attributed string wrapper for `NSString.paragraphRangeForRange()`
    ///
    func paragraphRange(for range: NSRange) -> NSRange {
        let swiftRange = string.range(fromUTF16NSRange: range)
        let outRange = string.paragraphRange(for: swiftRange)
        
        return string.utf16NSRange(from: outRange)
    }
    
    func paragraphRange(for attachment: NSTextAttachment) -> NSRange {
        // We assume the attachment IS in the string.  This method should not be called otherwise.
        let attachmentRange = ranges(forAttachment: attachment).first!
        
        return paragraphRange(for: attachmentRange)
    }
    
    // MARK: - Paragraph Ranges: Before and After
    
    func paragraphRange(after paragraphRange: NSRange) -> NSRange? {
        guard paragraphRange.upperBound < length,
            let newUpperBound = string.location(after: paragraphRange.upperBound) else {
                return nil
        }
        
        let rangeLength = newUpperBound - paragraphRange.upperBound
        let range = NSRange(location: paragraphRange.upperBound, length: rangeLength)
        
        return self.paragraphRange(for: range)
    }
    
    func paragraphRange(before paragraphRange: NSRange) -> NSRange? {
        guard paragraphRange.lowerBound > 0,
            let newLowerBound = string.location(before: paragraphRange.lowerBound) else {
                return nil
        }
        
        let rangeLength = paragraphRange.lowerBound - newLowerBound
        let range = NSRange(location: newLowerBound, length: rangeLength)
        
        return self.paragraphRange(for: range)
    }
    
    
    func paragraphRange(around range: NSRange, where match: ([ParagraphProperty]) -> Bool) -> NSRange? {
        let paragraphRange = self.paragraphRange(for: range)
        
        guard let paragraphStyle = self.attribute(.paragraphStyle, at: paragraphRange.lowerBound, effectiveRange: nil) as? ParagraphStyle,
            match(paragraphStyle.properties) else {
                return nil
        }
        
        var finalRange = paragraphRange
        
        enumerateParagraphRanges(before: paragraphRange) { (paragraphRange) -> Bool in
            guard let paragraphStyle = self.attribute(.paragraphStyle, at: paragraphRange.lowerBound, effectiveRange: nil) as? ParagraphStyle,
                match(paragraphStyle.properties) else {
                    return false
            }
            
            finalRange = NSRange(location: paragraphRange.lowerBound, length: finalRange.length + paragraphRange.length)
            return true
        }
        
        enumerateParagraphRanges(after: paragraphRange) { (paragraphRange) -> Bool in
            guard let paragraphStyle = self.attribute(.paragraphStyle, at: paragraphRange.lowerBound, effectiveRange: nil) as? ParagraphStyle,
                match(paragraphStyle.properties) else {
                    return false
            }
            
            finalRange = NSRange(location: finalRange.lowerBound, length: finalRange.length + paragraphRange.length)
            return true
        }
        
        return finalRange
    }
    
    // MARK: - Paragraph Ranges: Enumeration
    
    /// Enumerates the paragraph ranges after the specified paragraph range.
    ///
    /// - Parameters:
    ///     - paragraphRange: the reference paragraph range.
    ///     - step: closure executed for each paragraph range found after the reference one.  The return
    ///         value of this closure indicates if paragraph enumeration should continue (true is yes).
    ///
    func enumerateParagraphRanges(after paragraphRange: NSRange, using step: (NSRange) -> Bool) {
        var currentParagraphRange = paragraphRange
        
        while let followingParagraphRange = self.paragraphRange(after: currentParagraphRange) {
            guard step(followingParagraphRange) else {
                break
            }
            
            currentParagraphRange = followingParagraphRange
        }
    }
    
    /// Enumerates the paragraph ranges before the specified paragraph range.
    ///
    /// - Parameters:
    ///     - paragraphRange: the reference paragraph range.
    ///     - step: closure executed for each paragraph range found before the reference one.  The return
    ///         value of this closure indicates if paragraph enumeration should continue (true is yes).
    ///
    func enumerateParagraphRanges(before paragraphRange: NSRange, using step: (NSRange) -> Bool) {
        var currentParagraphRange = paragraphRange
        
        while let previousParagraphRange = self.paragraphRange(before: currentParagraphRange) {
            guard step(previousParagraphRange) else {
                break
            }
            
            currentParagraphRange = previousParagraphRange
        }
    }
    
    
    /// Enumerates all of the paragraphs spanning a NSRange
    ///
    /// - Parameters:
    ///     - range: Range that should be checked for paragraphs
    ///     - reverseOrder: Boolean indicating if the paragraphs should be enumerated in reverse order
    ///     - block: Closure to be executed for each paragraph
    ///
    func enumerateParagraphRanges(spanning range: NSRange, reverseOrder: Bool = false, using block: ((NSRange, NSRange) -> Void)) {
        var ranges = paragraphRanges(intersecting: range)
        if reverseOrder {
            ranges.reverse()
        }
        
        for (range, enclosingRange) in ranges {
            block(range, enclosingRange)
        }
    }
}
