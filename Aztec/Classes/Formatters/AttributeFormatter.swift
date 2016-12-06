import UIKit

/// A type that provides support for toggling compound attributes in an
/// attributed string.
///
/// When you want to represent an attribute that does not have a 1-1
/// correspondence with a standard attribute, it is useful to have a virtual
/// attribute. Toggling this attribute would also toggle the attributes for its
/// defined style.
///
protocol AttributeFormatter {
    /// Checks if the attribute is present in a dictionary of attributes.
    ///
    func present(inAttributes attributes: [String: AnyObject]) -> Bool

    /// The list of attributes that the compound attribute represents.
    ///
    var attributes: [String: AnyObject] { get }

    /// The range to apply the attributes to.
    ///
    /// By default, this returns the passed `range`, but implementations of this
    /// protocol might want to extend the range to apply the attribute to a
    /// different range (e.g. a paragraph)
    ///
    func applicationRange(forRange range: NSRange, inString string: NSAttributedString) -> NSRange

    /// Toggles an attribute in the specified range of a text view.
    ///
    /// If there is existing text to apply the attribute to, the formatter will
    /// do that. Otherwise, it will toggle the attributes in the text view's
    /// `typingAttributes` property.
    ///
    /// The application range might be different than the passed range, as
    /// explained in `applicationRange(forRange:inString:)`
    ///
    func toggleAttribute(inTextView textView: UITextView, atRange range: NSRange)
}

extension AttributeFormatter {
    /// Checks if the attribute is present in a text view at the specified index.
    ///
    func attribute(inTextView textView: UITextView, at index: Int) -> Bool {
        let string = textView.textStorage
        let range = applicationRange(forRange: NSRange(location: index, length: 0), inString: string)
        let attributes = range.length > 0
            ? string.attributes(at: index, effectiveRange: nil)
            : textView.typingAttributes
        return present(inAttributes: attributes as [String : AnyObject])
    }
}

// MARK: - Default implementations

extension AttributeFormatter {
    func applicationRange(forRange range: NSRange, inString string: NSAttributedString) -> NSRange {
        return range
    }

    /// The string to be used when adding attributes to an empty line.
    ///
    var placeholderForAttributedEmptyLine: String {
        return "\u{200B}"
    }
}

// MARK: - Private methods

private extension AttributeFormatter {
    func toggleTypingAttribute(inTextView textView: UITextView) {
        if present(inAttributes: textView.typingAttributes as [String : AnyObject]) {
            removeTypingAttribute(fromTextView: textView)
        } else {
            addTypingAttribute(toTextView: textView)
        }
    }

    func addTypingAttribute(toTextView textView: UITextView) {
        for (key, value) in attributes {
            textView.typingAttributes[key] = value
        }
    }

    func removeTypingAttribute(fromTextView textView: UITextView) {
        for (key, _) in attributes  {
            textView.typingAttributes.removeValue(forKey: key)
        }
    }

    func toggleAttribute(inString string: NSMutableAttributedString, atRange range: NSRange) {
        if attribute(inString: string, at: range.location) {
            removeAttributes(fromString: string, atRange: range)
        } else {
            applyAttributes(toString: string, atRange: range)
        }
    }

    func applyAttributes(toString string: NSMutableAttributedString, atRange range: NSRange) {
        string.addAttributes(attributes, range: range)
    }

    func removeAttributes(fromString string: NSMutableAttributedString, atRange range: NSRange) {
        for (attribute, _) in attributes {
            string.removeAttribute(attribute, range: range)
        }
    }

    func attribute(inString string: NSAttributedString, at index: Int) -> Bool {
        let attributes = string.attributes(at: index, effectiveRange: nil)
        return present(inAttributes: attributes as [String : AnyObject])
    }

    func insertEmptyAttribute(inString string: NSMutableAttributedString, at index: Int) {
        let attributedSpace = NSAttributedString(string: placeholderForAttributedEmptyLine, attributes: attributes)
        string.insert(attributedSpace, at: index)
    }
}

// MARK: - Attribute Formater types

protocol CharacterAttributeFormatter: AttributeFormatter {
}

extension CharacterAttributeFormatter {
    func toggleAttribute(inTextView textView: UITextView, atRange range: NSRange) {
        let applicationRange = self.applicationRange(forRange: range, inString: textView.textStorage)

//        guard applicationRange.length > 0 else {
//            toggleTypingAttribute(inTextView: textView)
//            return
//        }
        toggleAttribute(inString: textView.textStorage, atRange: applicationRange)
    }
}

protocol ParagraphAttributeFormatter: AttributeFormatter {
}

extension ParagraphAttributeFormatter {
    func applicationRange(forRange range: NSRange, inString string: NSAttributedString) -> NSRange {
        return string.paragraphRange(for: range)
    }

    func toggleAttribute(inTextView textView: UITextView, atRange range: NSRange) {
        let applicationRange = self.applicationRange(forRange: range, inString: textView.textStorage)

//        guard applicationRange.length > 0 else {
//            toggleTypingAttribute(inTextView: textView)
//            insertEmptyAttribute(inString: textView.textStorage, at: applicationRange.location)
//            return
//        }
        toggleAttribute(inString: textView.textStorage, atRange: applicationRange)
    }
}
