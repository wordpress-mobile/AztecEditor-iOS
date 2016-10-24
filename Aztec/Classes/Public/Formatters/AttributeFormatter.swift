import UIKit

protocol AttributeFormatter {
    func present(inAttributes attributes: [String: AnyObject]) -> Bool
    var attributes: [String: AnyObject] { get }
    func applicationRange(forRange range: NSRange, inString string: NSAttributedString) -> NSRange
}

extension AttributeFormatter {
    func attribute(inString string: NSAttributedString, at index: Int) -> Bool {
        let attributes = string.attributesAtIndex(index, effectiveRange: nil)
        return present(inAttributes: attributes)
    }

    func toggleAttribute(inString string: NSMutableAttributedString, atRange range: NSRange) {
        let applicationRange = self.applicationRange(forRange: range, inString: string)

        if attribute(inString: string, at: range.location) {
            removeAttributes(fromString: string, atRange: applicationRange)
        } else {
            applyAttributes(toString: string, atRange: applicationRange)
        }
    }
}

private extension AttributeFormatter {
    func toggleTypingAttribute(inTextView textView: UITextView) {
        if present(inAttributes: textView.typingAttributes) {
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
            textView.typingAttributes.removeValueForKey(key)
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
}

protocol CharacterAttributeFormatter: AttributeFormatter {
}

extension CharacterAttributeFormatter {
    func toggleAttribute(inTextView textView: UITextView, atRange range: NSRange) {
        guard range.length > 0 else {
            toggleTypingAttribute(inTextView: textView)
            return
        }
        toggleAttribute(inString: textView.textStorage, atRange: range)
    }


    func applicationRange(forRange range: NSRange, inString string: NSAttributedString) -> NSRange {
        return range
    }
}

protocol ParagraphAttributeFormatter: AttributeFormatter {
}

extension ParagraphAttributeFormatter {
    func toggleAttribute(inTextView textView: UITextView, atRange range: NSRange) {
        guard textView.textStorage.length > 0 else {
            toggleTypingAttribute(inTextView: textView)
            return
        }
        toggleAttribute(inString: textView.textStorage, atRange: range)
    }


    func applicationRange(forRange range: NSRange, inString string: NSAttributedString) -> NSRange {
        return string.paragraphRange(for: range)
    }
}
