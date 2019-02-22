import UIKit

protocol ParagraphAttributeFormatter: AttributeFormatter {
}

extension ParagraphAttributeFormatter {

    func applicationRange(for range: NSRange, in text: NSAttributedString) -> NSRange {
        return text.paragraphRange(for: range)
    }

    /// Applies the Formatter's Attributes into a given string, at the specified range.
    ///
    /// - Returns: the full range where the attributes where applied
    ///
    @discardableResult
    func applyAttributes(to text: NSMutableAttributedString, at range: NSRange) -> NSRange {
        let rangeToApply = applicationRange(for: range, in: text)

        text.replaceOcurrences(of: String(.lineFeed), with: String(.paragraphSeparator), within: rangeToApply)

        text.enumerateAttributes(in: rangeToApply, options: []) { (attributes, range, _) in
            let currentAttributes = text.attributes(at: range.location, effectiveRange: nil)
            let attributes = apply(to: currentAttributes)
            text.addAttributes(attributes, range: range)
        }

        return rangeToApply
    }

    /// Removes the Formatter's Attributes from a given string, at the specified range.
    ///
    /// - Returns: the full range where the attributes where removed
    ///
    @discardableResult
    func removeAttributes(from text: NSMutableAttributedString, at range: NSRange) -> NSRange {
        let rangeToApply = applicationRange(for: range, in: text)

        text.replaceOcurrences(of: String(.paragraphSeparator), with: String(.lineFeed), within: rangeToApply)
        
        text.enumerateAttributes(in: rangeToApply, options: []) { (attributes, range, stop) in
            let currentAttributes = text.attributes(at: range.location, effectiveRange: nil)
            let attributes = remove(from: currentAttributes)
            
            text.setAttributes(attributes, range: range)
        }

        return rangeToApply
    }
}
