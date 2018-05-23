import Foundation

extension NSMutableAttributedString {
    
    /// Returns a copy of the provided attributes appending the specified `ParagraphProperty` to the paragraph style.
    ///
    /// - Parameters:
    ///     - property: the property to append to the paragraph styles.
    ///     - attributes: the base attributes.
    ///
    /// - Returns: the final string attributes.
    ///
    func append(paragraphProperty property: ParagraphProperty) {
        enumerateParagraphRanges(spanning: self.rangeOfEntireString) { (_, range) in
            let attributes = self.attributes(at: range.lowerBound, effectiveRange: nil)
            let paragraphStyle = attributes.paragraphStyle()
            
            paragraphStyle.appendProperty(property)

            self.addAttribute(.paragraphStyle, value: paragraphStyle, range: range)
        }
    }
}

