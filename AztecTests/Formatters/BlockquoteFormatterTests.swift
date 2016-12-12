import XCTest
import Gridicons
@testable import Aztec

class BlockquoteFormatterTests: XCTestCase {
    func testApplyingBlockquoteOnFirstParagraph() {
        let textView = testTextView
        let paragraphs = paragraphRanges(inString: textView.storage)

        let formatter = BlockquoteFormatter()
        formatter.toggleAttribute(inTextView: textView, atRange: NSRange(location: 1, length: 1))

        XCTAssertTrue(existsBlockquote(for: textView.storage, in: paragraphs[0]))
    }

    func testRemovingBlockQuoteOnFirstParagraph() {
        let textView = testTextView
        let paragraphs = paragraphRanges(inString: textView.storage)

        let formatter = BlockquoteFormatter()
        textView.storage.setAttributes(formatter.attributes, range: paragraphs[0])
        formatter.toggleAttribute(inTextView: textView, atRange: NSRange(location: 1, length: 1))

        XCTAssertFalse(existsBlockquote(for: textView.storage, in: paragraphs[0]))
    }

    func testApplyingBlockquoteOnFirstParagraphWhenSecondHasBlockquote() {
        let textView = testTextView
        let paragraphs = paragraphRanges(inString: textView.storage)

        let formatter = BlockquoteFormatter()
        textView.storage.setAttributes(formatter.attributes, range: paragraphs[1])
        formatter.toggleAttribute(inTextView: textView, atRange: NSUnionRange(paragraphs[0], paragraphs[1]))

        XCTAssertTrue(existsBlockquote(for: textView.storage, in: paragraphs[0]))
        XCTAssertTrue(existsBlockquote(for: textView.storage, in: paragraphs[1]))
    }

    func testRemovingBlockQuoteOnFirstParagraphWhenSecondDoesNotHaveBlockquote() {
        let textView = testTextView
        let paragraphs = paragraphRanges(inString: textView.storage)

        let formatter = BlockquoteFormatter()
        textView.storage.setAttributes(formatter.attributes, range: paragraphs[0])
        formatter.toggleAttribute(inTextView: textView, atRange: NSUnionRange(paragraphs[0], paragraphs[1]))

        XCTAssertFalse(existsBlockquote(for: textView.storage, in: paragraphs[0]))
        XCTAssertFalse(existsBlockquote(for: textView.storage, in: paragraphs[1]))
    }

    func testToggleBlockquoteTwiceLeavesReturnsIdenticalString() {
        let textView = testTextView
        let paragraphs = paragraphRanges(inString: textView.storage)

        let formatter = BlockquoteFormatter()
        let original = textView.storage.copy() as! NSAttributedString
        formatter.toggleAttribute(inTextView: textView, atRange: NSUnionRange(paragraphs[0], paragraphs[1]))
        formatter.toggleAttribute(inTextView: textView, atRange: NSUnionRange(paragraphs[0], paragraphs[1]))

        XCTAssertTrue(original.isEqual(to: textView.storage))
    }
}

private extension BlockquoteFormatterTests {
    var testTextView: TextView {
        let view = TextView(defaultFont: UIFont.systemFont(ofSize: 14), defaultMissingImage: Gridicon.iconOfType(.image))
        view.text = plainText
        return view
    }
    var plainText: String {
        return plainTextParagraphLines.joined(separator: "")
    }

    var plainTextParagraphLines: [String] {
        return ["First line.\n", "Second Line.\n", "Third line!.\n", "Last but not least?.\n", "Last One!"]
    }

    func paragraphRanges(inString string: NSAttributedString) -> [NSRange] {
        return string.paragraphRanges(spanningRange: string.rangeOfEntireString)
    }

    func existsBlockquote(for string: NSMutableAttributedString, in range: NSRange) -> Bool {
        var effectiveRange = NSRange()
        guard let paragraphStyle = string.attribute(NSParagraphStyleAttributeName, at: range.location, effectiveRange: &effectiveRange) as? ParagraphStyle,
            let _ = paragraphStyle.blockquote else {
            return false
        }
        // Blockquote attribute spans the whole range
        return NSEqualRanges(range, NSIntersectionRange(range, effectiveRange))
    }
}
