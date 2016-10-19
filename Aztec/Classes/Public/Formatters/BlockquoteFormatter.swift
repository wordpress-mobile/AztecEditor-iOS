import Foundation
import UIKit

class Blockquote {
    static let attributeName = "AZBlockquote"
}

struct BlockquoteFormatter {
    func isBlockquote(inString string: NSAttributedString, at index: Int) -> Bool {
        return string.attribute(Blockquote.attributeName, atIndex: index, effectiveRange: nil) is Blockquote
    }

    func toggleBlockquote(inString string: NSMutableAttributedString, atRange range: NSRange) {
        let paragraphRanges = string.paragraphRanges(spanningRange: range)

        guard let unionRange = paragraphRanges.union() else {
            // paragraphRanges was empty, which should not happen
            return
        }

        if isBlockquote(inString: string, at: range.location) {
            removeBlockquote(fromString: string, atRange: unionRange)
        } else {
            applyBlockquote(toString: string, atRange: unionRange)
        }
    }

    let attributesForBlockquote: [String: AnyObject] = {
        let style = NSMutableParagraphStyle()
        style.headIndent = Metrics.defaultIndentation
        style.firstLineHeadIndent = style.headIndent
        style.tailIndent = -Metrics.defaultIndentation

        // We're going to need custom drawing to get the background that we want,
        // but for now let's use a light grey background to aid debugging.
        let backgroundColor = UIColor(white: 0.9, alpha: 1.0)

        return [
            NSBackgroundColorAttributeName: backgroundColor,
            NSParagraphStyleAttributeName: style,
            Blockquote.attributeName: Blockquote()
        ]
    }()
}

private extension BlockquoteFormatter {
    func applyBlockquote(toString string: NSMutableAttributedString, atRange range: NSRange) {
        string.addAttributes(attributesForBlockquote, range: range)
    }

    func removeBlockquote(fromString string: NSMutableAttributedString, atRange range: NSRange) {
        for (attribute, _) in attributesForBlockquote {
            string.removeAttribute(attribute, range: range)
        }
    }
}
