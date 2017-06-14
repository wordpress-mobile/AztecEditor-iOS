import UIKit

protocol ParagraphAttributeFormatter: AttributeFormatter {
    func apply(to attributes: [String: Any], andStore representation: HTMLElementRepresentation?) -> [String: Any]
}

extension ParagraphAttributeFormatter {

    func apply(to attributes: [String: Any], andStore representation: HTMLRepresentation?) -> [String: Any] {

        // TODO: this should be changed so that the method signature requires this, but in order to
        // do so we need a reengineering of the code that would be too big to tackle now.
        //
        guard let elementRepresentation = representation as? HTMLElementRepresentation else {
            fatalError("Never pass anything other than an element representation to a paragraph style.")
        }

        return apply(to: attributes, andStore: elementRepresentation)
    }

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

        text.replaceOcurrences(of: String(.newline), with: String(.paragraphSeparator), within: rangeToApply)

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

        text.replaceOcurrences(of: String(.paragraphSeparator), with: String(.newline), within: rangeToApply)

        text.enumerateAttributes(in: rangeToApply, options: []) { (attributes, range, stop) in
            let currentAttributes = text.attributes(at: range.location, effectiveRange: nil)
            let attributes = remove(from: currentAttributes)

            let currentKeys = Set(currentAttributes.keys)
            let newKeys = Set(attributes.keys)
            let removedKeys = currentKeys.subtracting(newKeys)
            for key in removedKeys {
                text.removeAttribute(key, range: range)
            }

            text.addAttributes(attributes, range: range)
        }

        return rangeToApply
    }
    
    func worksInEmptyRange() -> Bool {
        return true
    }
}
