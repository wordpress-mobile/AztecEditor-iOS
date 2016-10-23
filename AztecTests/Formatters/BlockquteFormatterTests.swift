import XCTest
@testable import Aztec

class BlockquteFormatterTests: XCTestCase {
    func testApplyingBlockquoteOnFirstParagraph() {
        let string = NSMutableAttributedString(string: plainText)
        let paragraphs = paragraphRanges(inString: string)

        let formatter = BlockquoteFormatter()
        formatter.toggleAttribute(inString: string, atRange: NSRange(location: 1, length: 1))

        XCTAssertTrue(existsBlockquote(for: string, in: paragraphs[0]))
    }

    func testRemovingBlockQuoteOnFirstParagraph() {
        let string = NSMutableAttributedString(string: plainText)
        let paragraphs = paragraphRanges(inString: string)

        let formatter = BlockquoteFormatter()
        string.setAttributes(formatter.attributes, range: paragraphs[0])
        formatter.toggleAttribute(inString: string, atRange: NSRange(location: 1, length: 1))

        XCTAssertFalse(existsBlockquote(for: string, in: paragraphs[0]))
    }

    func testApplyingBlockquoteOnFirstParagraphWhenSecondHasBlockquote() {
        let string = NSMutableAttributedString(string: plainText)
        let paragraphs = paragraphRanges(inString: string)

        let formatter = BlockquoteFormatter()
        string.setAttributes(formatter.attributes, range: paragraphs[1])
        formatter.toggleAttribute(inString: string, atRange: NSUnionRange(paragraphs[0], paragraphs[1]))

        XCTAssertTrue(existsBlockquote(for: string, in: paragraphs[0]))
        XCTAssertTrue(existsBlockquote(for: string, in: paragraphs[1]))
    }

    func testRemovingBlockQuoteOnFirstParagraphWhenSecondDoesNotHaveBlockquote() {
        let string = NSMutableAttributedString(string: plainText)
        let paragraphs = paragraphRanges(inString: string)

        let formatter = BlockquoteFormatter()
        string.setAttributes(formatter.attributes, range: paragraphs[0])
        formatter.toggleAttribute(inString: string, atRange: NSUnionRange(paragraphs[0], paragraphs[1]))

        XCTAssertFalse(existsBlockquote(for: string, in: paragraphs[0]))
        XCTAssertFalse(existsBlockquote(for: string, in: paragraphs[1]))
    }

    func testToggleBlockquoteTwiceLeavesReturnsIdenticalString() {
        let string = NSMutableAttributedString(string: plainText)
        let paragraphs = paragraphRanges(inString: string)

        let formatter = BlockquoteFormatter()
        let original = string.copy() as! NSAttributedString
        formatter.toggleAttribute(inString: string, atRange: NSUnionRange(paragraphs[0], paragraphs[1]))
        formatter.toggleAttribute(inString: string, atRange: NSUnionRange(paragraphs[0], paragraphs[1]))

        XCTAssertTrue(original.isEqualToAttributedString(string))
    }
}

private extension BlockquteFormatterTests {
    var plainText: String {
        return plainTextParagraphLines.joinWithSeparator("")
    }

    var plainTextParagraphLines: [String] {
        return ["First line.\n", "Second Line.\n", "Third line!.\n", "Last but not least?.\n", "Last One!"]
    }

    func paragraphRanges(inString string: NSAttributedString) -> [NSRange] {
        return string.paragraphRanges(spanningRange: string.rangeOfEntireString)
    }

    func existsBlockquote(`for` string: NSMutableAttributedString, `in` range: NSRange) -> Bool {
        var effectiveRange = NSRange()
        guard string.attribute(Blockquote.attributeName, atIndex: range.location, effectiveRange: &effectiveRange) != nil else {
            return false
        }
        // Blockquote attribute spans the whole range
        return NSEqualRanges(range, NSIntersectionRange(range, effectiveRange))
    }
}
