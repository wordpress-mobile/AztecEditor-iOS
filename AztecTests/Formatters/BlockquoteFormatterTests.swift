import XCTest
import Gridicons
@testable import Aztec

class BlockquoteFormatterTests: XCTestCase {
    func testApplyingBlockquoteOnFirstParagraph() {
        let textView = testTextView
        let storage = textView.storage
        let paragraphs = paragraphRanges(inString: storage)

        let formatter = BlockquoteFormatter()
        _ = formatter.toggle(in: storage, at: NSRange(location: 1, length: 1))

        XCTAssertTrue(existsBlockquote(for: textView.storage, in: paragraphs[0]))
    }

    func testRemovingBlockQuoteOnFirstParagraph() {
        let textView = testTextView
        let storage = textView.storage
        let paragraphs = paragraphRanges(inString: storage)

        let formatter = BlockquoteFormatter()
        var attributes = [String:Any]()
        attributes = formatter.apply(to: attributes)
        textView.storage.setAttributes(attributes, range: paragraphs[0])
        _ = formatter.toggle(in: storage, at: NSRange(location: 1, length: 1))

        XCTAssertFalse(existsBlockquote(for: textView.storage, in: paragraphs[0]))
    }

    func testApplyingBlockquoteOnFirstParagraphWhenSecondHasBlockquote() {
        let textView = testTextView
        let storage = textView.storage
        let paragraphs = paragraphRanges(inString: storage)

        let formatter = BlockquoteFormatter()
        var attributes = [String:Any]()
        attributes = formatter.apply(to: attributes)
        textView.storage.setAttributes(attributes, range: paragraphs[1])
        _ = formatter.toggle(in: storage, at: NSUnionRange(paragraphs[0], paragraphs[1]))

        XCTAssertTrue(existsBlockquote(for: textView.storage, in: paragraphs[0]))
        XCTAssertTrue(existsBlockquote(for: textView.storage, in: paragraphs[1]))
    }

    func testRemovingBlockQuoteOnFirstParagraphWhenSecondDoesNotHaveBlockquote() {
        let textView = testTextView
        let storage = textView.storage
        let paragraphs = paragraphRanges(inString: storage)

        let formatter = BlockquoteFormatter()
        var attributes = [String:Any]()
        attributes = formatter.apply(to: attributes)
        textView.storage.setAttributes(attributes, range: paragraphs[0])
        _ = formatter.toggle(in: storage, at: NSUnionRange(paragraphs[0], paragraphs[1]))

        XCTAssertFalse(existsBlockquote(for: textView.storage, in: paragraphs[0]))
        XCTAssertFalse(existsBlockquote(for: textView.storage, in: paragraphs[1]))
    }

    func testToggleBlockquoteTwiceLeavesReturnsIdenticalString() {
        let textView = testTextView
        let storage = textView.storage
        textView.storage.setAttributes([NSParagraphStyleAttributeName: ParagraphStyle.default], range: textView.storage.rangeOfEntireString)
        let paragraphs = paragraphRanges(inString: storage)

        let formatter = BlockquoteFormatter()
        let original = textView.storage.copy() as! NSAttributedString
        _ = formatter.toggle(in: storage, at: NSUnionRange(paragraphs[0], paragraphs[1]))
        _ = formatter.toggle(in: storage, at: NSUnionRange(paragraphs[0], paragraphs[1]))
        XCTAssertTrue(original.isEqual(to: textView.storage))
    }

    func testPresentInStorageAtIndexReturnsTrueWhenBlockquoteIsEffectivelyThere() {
        let textView = testTextView
        let storage = textView.storage
        let paragraphs = paragraphRanges(inString: storage)

        let formatter = BlockquoteFormatter()
        let blockquoteRange = paragraphs[1]
        _ = formatter.toggle(in: storage, at: blockquoteRange)

        for i in 0..<storage.length {
            let present = formatter.present(in: storage, at: i)

            if NSLocationInRange(i, blockquoteRange) {
                XCTAssertTrue(present)
            } else {
                XCTAssertFalse(present)
            }
        }
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
