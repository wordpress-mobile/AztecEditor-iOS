import XCTest
@testable import Aztec
import Gridicons

class AztecVisualEditorTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    // Confirm the composed textView is property configured.

    func testTextViewReferencesStorage() {

        let textView = Aztec.TextView(defaultFont: UIFont.systemFont(ofSize: 14), defaultMissingImage: Gridicon.iconOfType(.attachment))

        textView.text = "Foo"
        XCTAssert(textView.text == "Foo")
        XCTAssert(textView.text == textView.textStorage.string)
        XCTAssert(textView.attributedText == textView.textStorage)

        textView.attributedText = NSAttributedString(string: "Bar")
        XCTAssert(textView.text == "Bar")
        XCTAssert(textView.text == textView.textStorage.string)
        XCTAssert(textView.attributedText == textView.textStorage)

        XCTAssert(textView.textStorage == textView.layoutManager.textStorage)
        XCTAssert(textView.textStorage == textView.textContainer.layoutManager!.textStorage)
        XCTAssert(textView.textStorage.isKind(of: TextStorage.self))
    }


    // MARK: - Test Index Wrangling

    func testMaxIndex() {
        let textView = Aztec.TextView(defaultFont: UIFont.systemFont(ofSize: 14), defaultMissingImage: Gridicon.iconOfType(.attachment))

        textView.text = "foo"

        let count = textView.text!.characters.count
        let maxIndex = count - 1

        // Test upper and lower bounds
        XCTAssert(maxIndex == textView.maxIndex(100))
        XCTAssert(0 == textView.maxIndex(0))
    }

    func testAdjustedIndex() {
        let textView = Aztec.TextView(defaultFont: UIFont.systemFont(ofSize: 14), defaultMissingImage: Gridicon.iconOfType(.attachment))

        textView.text = "foobarbaz"

        let count = textView.text!.characters.count
        let maxIndex = count - 1

        // Test upper and lower bounds.
        // Remember that an adjusted character index should be one less than 
        // the NSRange.location.
        XCTAssert(maxIndex - 1 == textView.adjustedIndex(100))
        XCTAssert(0 == textView.adjustedIndex(0))
        XCTAssert(0 == textView.adjustedIndex(1))
        XCTAssert(1 == textView.adjustedIndex(2))
    }

    // MARK: - Retrieve Format Identifiers

    func testFormatIdentifiersSpanningRange() {
        let editor = editorConfiguredForTesting(withHTML: "foo<b>bar</b>baz")

        let range = NSRange(location: 3, length: 3)
        let identifiers = editor.formatIdentifiersSpanningRange(range)

        XCTAssert(identifiers.count == 1)
        XCTAssert(identifiers[0] == .bold)
    }

    func testFormatIdentifiersAtIndex() {
        let editor = editorConfiguredForTesting(withHTML: "foo<b>bar</b>baz")

        var identifiers = editor.formatIdentifiersAtIndex(4)
        XCTAssert(identifiers.count == 1)
        XCTAssert(identifiers[0] == .bold)

        identifiers = editor.formatIdentifiersAtIndex(5)
        XCTAssert(identifiers.count == 1)
        XCTAssert(identifiers[0] == .bold)

        identifiers = editor.formatIdentifiersAtIndex(6)
        XCTAssert(identifiers.count == 1)
        XCTAssert(identifiers[0] == .bold)


        identifiers = editor.formatIdentifiersAtIndex(0)
        XCTAssert(identifiers.count == 0)

        identifiers = editor.formatIdentifiersAtIndex(3)
        XCTAssert(identifiers.count == 0)

        identifiers = editor.formatIdentifiersAtIndex(7)
        XCTAssert(identifiers.count == 0)
    }

    // MARK: - Toggle Attributes

    func testToggleBold() {
        let editor = editorConfiguredForTesting(withHTML: "foo<b>bar</b>baz")
        let range = NSRange(location: 3, length: 3)

        XCTAssert(editor.boldFormattingSpansRange(range))

        editor.toggleBold(range: range)

        XCTAssert(!editor.boldFormattingSpansRange(range))

        editor.toggleBold(range: range)

        XCTAssert(editor.boldFormattingSpansRange(range))
    }

    func testToggleItalic() {
        let editor = editorConfiguredForTesting(withHTML: "foo<i>bar</i>baz")
        let range = NSRange(location: 3, length: 3)

        XCTAssert(editor.italicFormattingSpansRange(range))

        editor.toggleItalic(range: range)

        XCTAssert(!editor.italicFormattingSpansRange(range))

        editor.toggleItalic(range: range)

        XCTAssert(editor.italicFormattingSpansRange(range))
    }

    func testToggleUnderline() {
        let editor = editorConfiguredForTesting(withHTML: "foo<u>bar</u>baz")
        let range = NSRange(location: 3, length: 3)

        XCTAssert(editor.underlineFormattingSpansRange(range))

        editor.toggleUnderline(range: range)

        XCTAssert(!editor.underlineFormattingSpansRange(range))

        editor.toggleUnderline(range: range)

        XCTAssert(editor.underlineFormattingSpansRange(range))
    }

    func testToggleStrike() {
        let editor = editorConfiguredForTesting(withHTML: "foo<strike>bar</strike>baz")
        let range = NSRange(location: 3, length: 3)

        XCTAssert(editor.strikethroughFormattingSpansRange(range))

        editor.toggleStrikethrough(range: range)

        XCTAssert(!editor.strikethroughFormattingSpansRange(range))

        editor.toggleStrikethrough(range: range)

        XCTAssert(editor.strikethroughFormattingSpansRange(range))
    }

    func testToggleBlockquote() {
        let editor = editorConfiguredWithParagraphs()
        let length = paragraph.characters.count
        let range = NSRange(location: 0, length: length)

        editor.toggleBlockquote(range: range)

        XCTAssert(editor.formattingAtIndexContainsBlockquote(1))
        XCTAssert(editor.blockquoteFormattingSpansRange(range))

        editor.toggleBlockquote(range: range)

        XCTAssert(!editor.formattingAtIndexContainsBlockquote(1))
        XCTAssert(!editor.blockquoteFormattingSpansRange(range))
    }

    func testToggleOrderedList() {
        let editor = editorConfiguredWithParagraphs()
        let length = paragraph.characters.count
        let range = NSRange(location: 0, length: length)

        editor.toggleOrderedList(range: range)

        XCTAssert(editor.formattingAtIndexContainsOrderedList(0))
        XCTAssert(editor.orderedListFormattingSpansRange(range))

        editor.toggleOrderedList(range: range)

        XCTAssert(!editor.formattingAtIndexContainsOrderedList(0))
        XCTAssert(!editor.orderedListFormattingSpansRange(range))
    }

    func testToggleUnorderedList() {
        let editor = editorConfiguredWithParagraphs()
        let length = paragraph.characters.count
        let range = NSRange(location: 0, length: length)

        editor.toggleUnorderedList(range: range)

        XCTAssert(editor.formattingAtIndexContainsUnorderedList(0))
        XCTAssert(editor.unorderedListFormattingSpansRange(range))

        editor.toggleOrderedList(range: range)

        XCTAssert(!editor.formattingAtIndexContainsUnorderedList(0))
        XCTAssert(!editor.unorderedListFormattingSpansRange(range))
    }

    func testInsertLink() {
        // TODO
    }

    // MARK: - Test Attributes Exist

    func testBoldSpansRange() {
        let editor = editorConfiguredForTesting(withHTML: "foo<b>bar</b>baz")

        XCTAssert(editor.boldFormattingSpansRange(NSRange(location: 3, length: 3)))
        XCTAssert(editor.boldFormattingSpansRange(NSRange(location: 3, length: 2)))
        XCTAssert(editor.boldFormattingSpansRange(NSRange(location: 3, length: 1)))

        XCTAssert(!editor.boldFormattingSpansRange(NSRange(location: 2, length: 3)))
        XCTAssert(!editor.boldFormattingSpansRange(NSRange(location: 4, length: 3)))
    }

    func testItalicSpansRange() {
        let editor = editorConfiguredForTesting(withHTML: "foo<i>bar</i>baz")

        XCTAssert(editor.italicFormattingSpansRange(NSRange(location: 3, length: 3)))
        XCTAssert(editor.italicFormattingSpansRange(NSRange(location: 3, length: 2)))
        XCTAssert(editor.italicFormattingSpansRange(NSRange(location: 3, length: 1)))

        XCTAssert(!editor.italicFormattingSpansRange(NSRange(location: 2, length: 3)))
        XCTAssert(!editor.italicFormattingSpansRange(NSRange(location: 4, length: 3)))
    }

    func testUnderlineSpansRange() {
        let editor = editorConfiguredForTesting(withHTML: "foo<u>bar</u>baz")

        XCTAssert(editor.underlineFormattingSpansRange(NSRange(location: 3, length: 3)))
        XCTAssert(editor.underlineFormattingSpansRange(NSRange(location: 3, length: 2)))
        XCTAssert(editor.underlineFormattingSpansRange(NSRange(location: 3, length: 1)))

        XCTAssert(!editor.underlineFormattingSpansRange(NSRange(location: 2, length: 3)))
        XCTAssert(!editor.underlineFormattingSpansRange(NSRange(location: 4, length: 3)))
    }

    func testStrikethroughSpansRange() {
        let editor = editorConfiguredForTesting(withHTML: "foo<strike>bar</strike>baz")

        XCTAssert(editor.strikethroughFormattingSpansRange(NSRange(location: 3, length: 3)))
        XCTAssert(editor.strikethroughFormattingSpansRange(NSRange(location: 3, length: 2)))
        XCTAssert(editor.strikethroughFormattingSpansRange(NSRange(location: 3, length: 1)))

        XCTAssert(!editor.strikethroughFormattingSpansRange(NSRange(location: 2, length: 3)))
        XCTAssert(!editor.strikethroughFormattingSpansRange(NSRange(location: 4, length: 3)))
    }

    func testBlockquoteSpansRange() {
        let editor = editorConfiguredWithParagraphs()
        let range = NSRange(location: 0, length: 1)
        let length = "Lorem ipsum dolar sit amet.\n".characters.count

        editor.toggleBlockquote(range: range)

        XCTAssert(editor.blockquoteFormattingSpansRange(NSRange(location: 0, length: length)))
        XCTAssert(!editor.blockquoteFormattingSpansRange(NSRange(location: 0, length: length + 1)))
        XCTAssert(!editor.blockquoteFormattingSpansRange(NSRange(location: 1, length: length)))
    }

    func testBoldAtIndex() {
        let editor = editorConfiguredForTesting(withHTML: "foo<b>bar</b>baz")

        XCTAssert(editor.formattingAtIndexContainsBold(3))
        XCTAssert(editor.formattingAtIndexContainsBold(4))
        XCTAssert(editor.formattingAtIndexContainsBold(5))

        XCTAssert(!editor.formattingAtIndexContainsBold(2))
        XCTAssert(!editor.formattingAtIndexContainsBold(6))
    }

    func testItalicAtIndex() {
        let editor = editorConfiguredForTesting(withHTML: "foo<i>bar</i>baz")

        XCTAssert(editor.formattingAtIndexContainsItalic(3))
        XCTAssert(editor.formattingAtIndexContainsItalic(4))
        XCTAssert(editor.formattingAtIndexContainsItalic(5))

        XCTAssert(!editor.formattingAtIndexContainsItalic(2))
        XCTAssert(!editor.formattingAtIndexContainsItalic(6))
    }

    func testUnderlineAtIndex() {
        let editor = editorConfiguredForTesting(withHTML: "foo<u>bar</u>baz")

        XCTAssert(editor.formattingAtIndexContainsUnderline(3))
        XCTAssert(editor.formattingAtIndexContainsUnderline(4))
        XCTAssert(editor.formattingAtIndexContainsUnderline(5))

        XCTAssert(!editor.formattingAtIndexContainsUnderline(2))
        XCTAssert(!editor.formattingAtIndexContainsUnderline(6))
    }

    func testStrikethroughAtIndex() {
        let editor = editorConfiguredForTesting(withHTML: "foo<strike>bar</strike>baz")

        XCTAssert(editor.formattingAtIndexContainsStrikethrough(3))
        XCTAssert(editor.formattingAtIndexContainsStrikethrough(4))
        XCTAssert(editor.formattingAtIndexContainsStrikethrough(5))

        XCTAssert(!editor.formattingAtIndexContainsStrikethrough(2))
        XCTAssert(!editor.formattingAtIndexContainsStrikethrough(6))
    }

    func testBlockquoteAtIndex() {
        let editor = editorConfiguredWithParagraphs()
        let range = NSRange(location: 0, length: 1)

        XCTAssert(!editor.formattingAtIndexContainsBlockquote(1))

        editor.toggleBlockquote(range: range)

        XCTAssert(editor.formattingAtIndexContainsBlockquote(1))

        editor.toggleBlockquote(range: range)

        XCTAssert(!editor.formattingAtIndexContainsBlockquote(1))
    }

    // MARK: - Helpers
    let paragraph = "Lorem ipsum dolar sit amet.\n"

    func editorConfiguredForTesting(withHTML html: String) -> Aztec.TextView {
        let richTextView = Aztec.TextView(defaultFont: UIFont.systemFont(ofSize: 14), defaultMissingImage: Gridicon.iconOfType(.attachment))

        richTextView.setHTML(html)

        return richTextView
    }

    func editorConfiguredWithParagraphs() -> Aztec.TextView {
        let richTextView = Aztec.TextView(defaultFont: UIFont.systemFont(ofSize: 14), defaultMissingImage: Gridicon.iconOfType(.attachment))

        let attributes = [NSParagraphStyleAttributeName : NSParagraphStyle()]
        let templateString = NSMutableAttributedString(string: paragraph, attributes: attributes)

        let attrStr = NSMutableAttributedString()
        attrStr.append(templateString)
        attrStr.append(templateString)
        attrStr.append(templateString)
        richTextView.attributedText = attrStr

        return richTextView
    }
}
